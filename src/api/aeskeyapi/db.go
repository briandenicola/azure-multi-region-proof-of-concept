package aeskeyapi

import (
	"context"
	"encoding/json"
	"log/slog"
	"os"
	"time"

	azcosmos "github.com/Azure/azure-sdk-for-go/sdk/data/azcosmos"
	azeventhubs "github.com/Azure/azure-sdk-for-go/sdk/messaging/azeventhubs"
	"github.com/redis/go-redis/v9"
)

// DB Interface
type DB interface {
	Get(id string) (*AesKey, error)
	Add(k *AesKey)
	Save() ([]*AesKey, error)
	Flush()
}

// AESKeyDB Structure
type AESKeyDB struct {
	DatabaseName  string
	ContainerName string
	EventHub      string
	ClientID      string
	CacheEnabled  bool

	slogger *slog.Logger

	producerClient *azeventhubs.ProducerClient
	redisClient    *redis.Client

	cosmosClient   *azcosmos.Client
	cosmosContainer *azcosmos.ContainerClient
	
	keys            []*AesKey
}

// NewKeysDB - Initialize connections to Event Hub, Cosmos and Redis
func NewKeysDB(useCache bool) (*AESKeyDB, error) {
	var err error

	db := new(AESKeyDB)
	db.DatabaseName = COSMOS_DATABASE_NAME
	db.ContainerName = COSMOS_COLLECTION_NAME
	db.EventHub = EVENT_HUB_NAME

	db.ClientID = os.Getenv("APPLICATION_CLIENT_ID")
	EventHubNsConnectionString := os.Getenv("EVENTHUB_CONNECTIONSTRING")
	RedisConnectionString := os.Getenv("REDISCACHE_CONNECTIONSTRING")
	CosmosConnectionString := os.Getenv("COSMOSDB_CONNECTIONSTRING")

	jsonHandler := slog.NewJSONHandler(os.Stderr, nil)
	db.slogger = slog.New(jsonHandler)

	//Event Hub Setup
	db.slogger.Info("DB Setup and Authentication", "EventHub Connection String", EventHubNsConnectionString, "ClientID", db.ClientID, "EventHub", db.EventHub)
	db.producerClient, err = handleEventHubAuthentication(EventHubNsConnectionString, db.EventHub, db.ClientID, db.slogger)

	if err != nil {
		panic(err)
	}

	//Redis Cache Setup
	if useCache {
		db.slogger.Info("DB Setup and Authentication", "Redis Connection String", RedisConnectionString, "ClientID", db.ClientID)
		db.redisClient, db.CacheEnabled = handleRedisAuthentication(RedisConnectionString, db.ClientID, db.slogger)
	} else {
		db.CacheEnabled = false
	}

	//Cosmos DB Setup
	db.cosmosClient, db.cosmosContainer, err = handleCosmosDBAuthentication(CosmosConnectionString, db.DatabaseName, db.ContainerName, db.slogger)
	if err != nil {
		panic(err)
	}

	return db, nil
}

// Save - Write AES Key object to Azure Event Hub
func (k *AESKeyDB) Save() ([]*AesKey, error) {

	var (
		err error
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

// Get - Retrieve AES Key object from Redis cache or Cosmos DB
func (k *AESKeyDB) Get(id string) (*AesKey, error) {
	var key *AesKey
	var err error

	ctx, cancel := context.WithTimeout(context.Background(), 20*time.Second)
	defer cancel()

	if k.CacheEnabled {
		k.slogger.Info("Redis Cache", "UseCached", k.CacheEnabled)
		result, err := k.redisClient.Get(ctx, id).Result()

		if err == nil {
			_ = json.Unmarshal([]byte(result), &key)
			k.slogger.Info("Redis Cache Read Details", "Key Details", key)
			key.FromCache = true
			return key, nil
		}
	}

	cosmosPartitionKey := azcosmos.NewPartitionKeyString(COSMOS_PARTITION_KEY_VALUE)
	itemResponse, _ := k.cosmosContainer.ReadItem(ctx, cosmosPartitionKey, id, nil)
	err = json.Unmarshal(itemResponse.Value, &key)

	if err == nil {
		k.slogger.Info("CosmosDB Read Details", "Key Details", key)
		return key, nil
	}

	k.slogger.Error("CosmosDB Read Details", "Error Details", err)
	return nil, err
}

// Add - Add key to local cache of AESKeys
func (k *AESKeyDB) Add(key *AesKey) {
	k.slogger.Info("Add Key to local cache of keys", "Key Details", key)
	k.keys = append(k.keys, key)
}

// Flush - Reset stored AESKeys
func (k *AESKeyDB) Flush() {
	k.slogger.Info("Flush local cache of keys")
	k.keys = nil
}
