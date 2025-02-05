package aeskeyapi

import (
	"context"
	"crypto/tls"
	"encoding/json"
	"log"
	"log/slog"
	"os"
	"time"

	azcore "github.com/Azure/azure-sdk-for-go/sdk/azcore"
	"github.com/Azure/azure-sdk-for-go/sdk/azidentity"
	azcosmos "github.com/Azure/azure-sdk-for-go/sdk/data/azcosmos"
	azeventhubs "github.com/Azure/azure-sdk-for-go/sdk/messaging/azeventhubs"
	"github.com/redis/go-redis/v9"
)

//DB Interface
type DB interface {
	Get(id string) (*AesKey, error)
	Add(k *AesKey)
	Save() ([]*AesKey, error)
	Flush()
}

//AESKeyDB Structure
type AESKeyDB struct {
	DatabaseName   		string
	ContainerName 		string
	EventHub   			string
	EventHubNamespace 	string
	ClientID   			string
	CacheEnabled 		bool

	slogger  		    *slog.Logger

	producerClient  	*azeventhubs.ProducerClient
	redisClient  		*redis.Client
	cosmosClient 		*azcosmos.Client

	cosmosContainer 	*azcosmos.ContainerClient
	cosmosDatabase 		*azcosmos.DatabaseClient
	cosmosPartitionKey 	azcosmos.PartitionKey
	keys 				[]*AesKey
}

//NewKeysDB - Initialize connections to Event Hub, Cosmos and Redis
func NewKeysDB(useCache bool) (*AESKeyDB, error) {
	var err error

	db := new(AESKeyDB)
	db.DatabaseName = COSMOS_DATABASE_NAME
	db.ContainerName = COSMOS_COLLECTION_NAME
	db.EventHub = EVENT_HUB_NAME
	db.EventHubNamespace = os.Getenv("EVENTHUB_CONNECTIONSTRING")
	db.ClientID = os.Getenv("APPLICATION_CLIENT_ID")

	jsonHandler := slog.NewJSONHandler(os.Stderr, nil)
	db.slogger = slog.New(jsonHandler)

	managed, err := azidentity.NewManagedIdentityCredential(&azidentity.ManagedIdentityCredentialOptions{
		ID: azidentity.ClientID(db.ClientID),
	})
	if err != nil {
		db.slogger.Error("NewManagedIdentityCredential", "Error", err)
	}

	workload, err := azidentity.NewWorkloadIdentityCredential(&azidentity.WorkloadIdentityCredentialOptions{
		ClientID: db.ClientID,
	})
	if err != nil {
		db.slogger.Error("WorkloadIdentityCredential", "Error", err)
	}

	azCLI, err := azidentity.NewAzureCLICredential(nil)
	if	err != nil {
		db.slogger.Error("NewAzureCLICredential", "Error", err)
	}
	credChain, err := azidentity.NewChainedTokenCredential([]azcore.TokenCredential{azCLI, workload, managed}, nil)

	db.producerClient, err = azeventhubs.NewProducerClient(db.EventHubNamespace, db.EventHub, credChain, nil)
	if err != nil {
		panic(err)
	}	
	db.slogger.Info("Event Hub Setup", "Namespace", db.EventHubNamespace, "Event Hub", db.EventHub)

	db.CacheEnabled = useCache
	if(db.CacheEnabled == true) {
		db.redisClient = redis.NewClient(&redis.Options{
			Addr:      					os.Getenv("REDISCACHE_CONNECTIONSTRING"),
			CredentialsProviderContext: handleRedisAuthentication(),
			TLSConfig:                  &tls.Config{MinVersion: tls.VersionTLS12},
		})
		if( db.redisClient == nil) {
			log.Print("Error Connecting to Redis Cache")
			db.CacheEnabled = false
		}
	}

	clientOptions := azcosmos.ClientOptions{
		EnableContentResponseOnWrite: true,
	}

	db.slogger.Info("Cosmos Setup", "Connection String", os.Getenv("COSMOSDB_CONNECTIONSTRING"))
	db.cosmosPartitionKey = azcosmos.NewPartitionKeyString("keyId")
	db.cosmosClient, err = azcosmos.NewClientFromConnectionString(os.Getenv("COSMOSDB_CONNECTIONSTRING"), &clientOptions)
	if err != nil {
		panic(err)
	}

	db.cosmosDatabase, err = db.cosmosClient.NewDatabase(db.DatabaseName)
	if err != nil {
		panic(err)
	}
	db.cosmosContainer, err = db.cosmosDatabase.NewContainer(db.ContainerName)

	return db, nil
}

//Save - Write AES Key object to Azure Event Hub
func (k *AESKeyDB) Save() ([]*AesKey, error) {

	var (
		err    error
	)
	_, cancel := context.WithTimeout(context.Background(), 20*time.Second)
	defer cancel()
	
	batchOptions := &azeventhubs.EventDataBatchOptions{}
	batch, err := k.producerClient.NewEventDataBatch(context.TODO(), batchOptions)

	for index := range k.keys {
		encodedAesKey := encodeForEventHub(k.keys[index])
		k.slogger.Info("Event Hub Save", "Key Details", encodedAesKey)
		err = batch.AddEventData(&encodedAesKey, nil)
	}

	if batch.NumEvents() > 0 {
		if err := k.producerClient.SendEventDataBatch(context.TODO(), batch, nil); err != nil {
			k.slogger.Error("Event Hub SendBatch Issue", "Error", err)
			panic(err)
		}
	}
	return k.keys, err
}

func encodeForEventHub(data *AesKey) azeventhubs.EventData {
	encoded, _ := json.Marshal(data)
	return azeventhubs.EventData{
		Body: encoded,
	}
}

//Get - Retrieve AES Key object from Redis cache or Cosmos DB
func (k *AESKeyDB) Get(id string) (*AesKey, error) {
	var keys []*AesKey
	var key *AesKey
	var err error

	ctx, cancel := context.WithTimeout(context.Background(), 20*time.Second)
	defer cancel()

	if( k.CacheEnabled == true) {
		k.slogger.Info("Redis Cache", "UseCached", k.CacheEnabled)
		result, err := k.redisClient.Get(ctx, id).Result()

		if err == nil {
			_ = json.Unmarshal([]byte(result), &key)
			k.slogger.Info("Redis Cache Read Details", "Key Details", key)
			key.FromCache = true
			return key, nil
		}
	}
	
	itemResponse, _ := k.cosmosContainer.ReadItem(ctx, k.cosmosPartitionKey, id, nil)
	err = json.Unmarshal(itemResponse.Value, &keys)

	if err == nil && len(keys) != 0 {
		k.slogger.Info("CosmosDB Read Details", "Key Details", keys[0])
		return keys[0], nil
	}

	k.slogger.Error("CosmosDB Read Details", "Error Details", err)
	return nil, err
}

//Add - Add key to local cache of AESKeys
func (k *AESKeyDB) Add(key *AesKey) {
	k.slogger.Info("Add Key to local cache of keys", "Key Details", key)
	k.keys = append(k.keys, key)
}

//Flush - Reset stored AESKeys
func (k *AESKeyDB) Flush() {
	k.slogger.Info("Flush local cache of keys")
	k.keys = nil
}