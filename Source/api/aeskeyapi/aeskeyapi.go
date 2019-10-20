package aeskeyapi

import (
	"context"
	"encoding/json"
	"crypto/tls"
	"io/ioutil"
	"time"
	"os"
	"net/http"
	"fmt"
	"log"
	"github.com/gorilla/mux"
	"github.com/rs/cors"
	"github.com/Azure/azure-event-hubs-go/v2"
	"github.com/go-redis/redis/v7"
)

var (
	kafkaClient *eventhub.Hub
	redisClient *redis.Client
	//cosmosClient
)

type newAPIHandler struct { }
func (eh *newAPIHandler) readRequestBody(r *http.Request) (int) {

	var (
		k RequestBody
	)

	b, _ := ioutil.ReadAll(r.Body)
	json.Unmarshal(b, &k)
	return k.NumberOfKeys	

}

func (eh *newAPIHandler) sendEvents(events []*eventhub.Event) (error) {

	var (
		err   error
	)

	ctx, cancel := context.WithTimeout(context.Background(), 20*time.Second)
	defer cancel()

	err = kafkaClient.SendBatch(ctx, eventhub.NewEventBatchIterator(events...))
	return err

}

func (eh *newAPIHandler) writeJsonReply (w http.ResponseWriter, r *http.Request, keys []*AesKey) {
	w.Header().Set("Content-Type", "application/json; charset=UTF-8")
	json.NewEncoder(w).Encode(keys)
}

func (eh *newAPIHandler) getAesKeysHandler(w http.ResponseWriter, r *http.Request) {

	var(
		key *AesKey
	)

	vars := mux.Vars(r)
	id := vars["id"]
	
	result, err := redisClient.Get(id).Result()

	if err == redis.Nil {
		key = new(AesKey)
	} else if err != nil {
		fmt.Println(err)
		return
	} else {
		_ = json.Unmarshal([]byte(result), &key)
	}

	eh.writeJsonReply(w,r, []*AesKey{key})
}

func (eh *newAPIHandler) newAesKeyHandler(w http.ResponseWriter, r *http.Request) {
	
	var(
		events  []*eventhub.Event
		aesKeys []*AesKey
		i       int = 0
	)
	
	keysToGenerator := eh.readRequestBody(r)

	for i < keysToGenerator {
		
		key := createKeyObject()
		aesKeys = append(aesKeys, key)

		encodedAesKey, err := json.Marshal(key)
		if err == nil {
			events  = append(events, eventhub.NewEvent(encodedAesKey))
		}

		i += 1
	}

	err := eh.sendEvents(events)
	if err != nil {
		fmt.Println(err)
		return
	}

	eh.writeJsonReply(w,r, aesKeys)

}

func (eh *newAPIHandler) optionsHandler(w http.ResponseWriter, r *http.Request) {
	w.WriteHeader(200)
}

func (eh *newAPIHandler) InitHttpServer(port string) {

	var (
		err   	  error
		hubName = "events"
	)

	kafkaConStr := os.Getenv("EVENTHUB_CONNECTIONSTRING") + ";EntityPath=" + hubName
	kafkaClient, err = eventhub.NewHubFromConnectionString(kafkaConStr)
	if err != nil {
		fmt.Println(err)
		return
	}
	
	redisServer, redisPasswords := parseRedisConnectionString( os.Getenv("REDISCACHE_CONNECTIONSTRING") )
	redisClient = redis.NewClient(&redis.Options{
		Addr:     		redisServer,
		Password: 		redisPasswords, 
		DB:       		0,  
		TLSConfig:		&tls.Config{InsecureSkipVerify: true},
	})
	defer redisClient.Close()

	r := mux.NewRouter()
	apirouter := r.PathPrefix("/api").Subrouter()
	apirouter.Methods("GET").Path("/keys/{id}").HandlerFunc(eh.getAesKeysHandler)
	apirouter.Methods("POST").Path("/keys").HandlerFunc(eh.newAesKeyHandler)
	apirouter.Methods("OPTIONS").Path("/keys").HandlerFunc(eh.optionsHandler)

	server := cors.Default().Handler(r)

	fmt.Print("Listening on ", port)
	log.Fatal(http.ListenAndServe( port , server))
}

func NewAPIHandler() *newAPIHandler {
	return &newAPIHandler{}
}