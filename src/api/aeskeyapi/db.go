package aeskeyapi

import (
	"context"
	"crypto/tls"
	"encoding/json"
	"log"
	"os"
	"time"

	"github.com/Azure/azure-sdk-for-go/sdk/data/azcosmos"
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
	DatabaseName   	string
	ContainerName 	string
	EventHub   		string
	CacheEnabled 	bool

	kafkaClient  		*azeventhubs.ProducerClient
	redisClient  		*redis.Client
	cosmosClient 		*azcosmos.Client

	cosmosContainer 	*azcosmos.ContainerClient
	cosmosDatabase 		*azcosmos.DatabaseClient
	cosmosPartitionKey 	azcosmos.PartitionKey
	keys []*AesKey
}

//NewKeysDB - Initialize connections to Event Hub, Cosmos and Redis
func NewKeysDB(useCache bool) (*AESKeyDB, error) {
	var err error

	db := new(AESKeyDB)
	db.DatabaseName = COSMOS_DATABASE_NAME
	db.ContainerName = COSMOS_COLLECTION_NAME
	db.EventHub = EVENT_HUB_NAME

	defaultAzureCred, err := azidentity.NewDefaultAzureCredential(nil)
	db.kafkaClient, _ := azeventhubs.NewProducerClient(os.Getenv("EVENTHUB_CONNECTIONSTRING"), db.EventHub, defaultAzureCred, nil)

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
	db.cosmosPartitionKey = azcosmos.NewPartitionKeyString("keyId")
	db.cosmosClient, err = azcosmos.NewClientFromConnectionString(os.Getenv("COSMOS_CONNECTIONSTRING"), &clientOptions)
	if err != nil {
		panic("Error Connecting to Cosmos")
	}

	db.cosmosDatabase, err = db.cosmosClient.NewDatabase(db.DatabaseName)
	if err != nil {
		panic("Error Connecting to Cosmos Database")
	}
	db.cosmosContainer, err = db.cosmosDatabase.NewContainer(db.ContainerName)

	return db, nil
}

//Save - Write AES Key object to Azure Event Hub
func (k *AESKeyDB) Save() ([]*AesKey, error) {

	var (
		err    error
		events []*eventhub.Event
	)

	ctx, cancel := context.WithTimeout(context.Background(), 20*time.Second)
	defer cancel()

	for index := range k.keys {
		encodedAesKey, _ := json.Marshal(k.keys[index])
		events = append(events, eventhub.NewEvent(encodedAesKey))
	}

	err = k.kafkaClient.SendBatch(ctx, eventhub.NewEventBatchIterator(events...))
	return k.keys, err
}

//Get - Retrieve AES Key object from Redis cache or Cosmos DB
func (k *AESKeyDB) Get(id string) (*AesKey, error) {
	var keys []*AesKey
	var key *AesKey
	var err error

	ctx, cancel := context.WithTimeout(context.Background(), 20*time.Second)
	defer cancel()

	if( k.CacheEnabled == true) {
		result, err := k.redisClient.Get(ctx, id).Result()

		if err == nil {
			_ = json.Unmarshal([]byte(result), &key)
			key.FromCache = true
			return key, nil
		}
	}
	
	itemResponse, _ := k.cosmosContainer.ReadItem(ctx, k.cosmosPartitionKey, id, nil)
	err = json.Unmarshal(itemResponse.Value, &keys)

	if err == nil && len(keys) != 0 {
		return keys[0], nil
	}

	return nil, err
}

//Add - Add key to local cache of AESKeys
func (k *AESKeyDB) Add(key *AesKey) {
	k.keys = append(k.keys, key)
}

//Flush - Reset stored AESKeys
func (k *AESKeyDB) Flush() {
	k.keys = nil
}