package aeskeyapi

import (
	"context"
	"crypto/tls"
	"time"
	"os"
	"encoding/json"
	"github.com/Azure/azure-event-hubs-go/v3"
	"github.com/go-redis/redis/v8"
	"github.com/a8m/documentdb"
)

//DB Interface 
type DB interface {
	Get(id string) (*AesKey,error)
	Add(k *AesKey)
	Save() ([]*AesKey,error)
	Flush()
}

//AESKeyDB Structure 
type AESKeyDB struct {
	Database   string
	Collection string
	EventHub   string

	kafkaClient *eventhub.Hub
	redisClient *redis.Client
	cosmosClient *documentdb.DocumentDB

	db         *documentdb.Database
	collection *documentdb.Collection
	
	keys	   []*AesKey
}

//NewKeysDB - Initialize connections to Event Hub, Cosmos and Redis 
func NewKeysDB() (*AESKeyDB, error){
	var err error

	db := new(AESKeyDB)
	db.Database   = COSMOS_DATABASE_NAME 
	db.Collection = COSMOS_COLLECTION_NAME
	db.EventHub   = EVENT_HUB_NAME

	kafkaConStr := parseEventHubConnectionString( os.Getenv("EVENTHUB_CONNECTIONSTRING") ) 
	db.kafkaClient, _ = eventhub.NewHubFromConnectionString(kafkaConStr)
	
	redisServer, redisPasswords := parseRedisConnectionString( os.Getenv("REDISCACHE_CONNECTIONSTRING") )
	db.redisClient = redis.NewClient(&redis.Options{
		Addr:     		redisServer,
		Password: 		redisPasswords, 
		DB:       		0,
		TLSConfig:		&tls.Config{InsecureSkipVerify: true},
	})
	//defer db.redisClient.Close()

	cosmsosURL, cosomosMasterKey := parseCosmosConnectionString( os.Getenv("COSMOSDB_CONNECTIONSTRING") )
	cosmosConfig := documentdb.NewConfig(&documentdb.Key{
		Key: cosomosMasterKey,
	})
	db.cosmosClient = documentdb.New(cosmsosURL, cosmosConfig)

	err = db.findDatabase(db.Database)
	if err != nil {
		panic(err)
	}
	db.findCollection(db.Collection)

	return db, nil
}

//Save - Write AES Key object to Azure Event Hub
func (k *AESKeyDB) Save() ([]*AesKey,error) {

	var(
		 err   	error
		 events	[]*eventhub.Event
	)

	ctx, cancel := context.WithTimeout(context.Background(), 20*time.Second)
	defer cancel()

	for index := range k.keys {
		encodedAesKey, _ := json.Marshal(k.keys[index])
		events  = append(events, eventhub.NewEvent(encodedAesKey))
	}

	err = k.kafkaClient.SendBatch(ctx, eventhub.NewEventBatchIterator(events...))
	return k.keys, err
}

//Get - Retrieve AES Key object from Redis cache or Cosmos DB 
func (k *AESKeyDB) Get(id string)(*AesKey,error) {
	var keys []*AesKey
	var key  *AesKey
	var err  error 

	ctx, cancel := context.WithTimeout(context.Background(), 20*time.Second)
	defer cancel()

	result, err := k.redisClient.Get(ctx, id).Result()
	
	if err == nil {
		_ = json.Unmarshal([]byte(result), &key)
		key.FromCache = true
		return key, nil
	}

	query := documentdb.NewQuery("SELECT * FROM c WHERE c.keyId=@keyId", documentdb.P{Name: "@keyId", Value: id})
	_, err = k.cosmosClient.QueryDocuments(k.collection.Self, query, &keys)

	if err == nil && len(keys) != 0  {
		return keys[0],nil
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

//findCollection Finds Collection in CosmosDB Account
func (k *AESKeyDB) findCollection(name string) (err error) {

	query := documentdb.NewQuery("SELECT * FROM ROOT r WHERE r.id=@name", documentdb.P{Name: "@name", Value: name})
	colls, err := k.cosmosClient.QueryCollections(k.db.Self, query);
	if err != nil {
		return err
	} 
	
	k.collection = &colls[0]	
	return
}

//findDatabase - Finds Database in CosmosDB Account
func (k *AESKeyDB) findDatabase(name string) (err error) {
	
	query := documentdb.NewQuery("SELECT * FROM ROOT r WHERE r.id=@name", documentdb.P{Name: "@name", Value: name})
	dbs, err := k.cosmosClient.QueryDatabases(query);
	if err != nil {
		return err
	} 

	k.db = &dbs[0]
	return
}