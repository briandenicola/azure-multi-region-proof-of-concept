package aeskeyapi

import (
	"context"
	"encoding/json"
	"crypto/rand"
	"io/ioutil"
	"time"
	"os"
	"net/http"
	"encoding/base64"
	"fmt"
	"log"
	"github.com/gorilla/mux"
	"github.com/rs/cors"
	"github.com/Azure/azure-event-hubs-go"
)

var (
	client *eventhub.Hub
)

type RequestBody struct {
	NumberOfKeys int
}

type AesKey struct {
	KeyId 		string	`json:"keyId"`
	Key   		string	`json:"key"`
	Host  		string	`json:"host"`
	TimeStamp 	string	`json:"timeStamp"`
}

func createUUID() (string) {

	buf := make([]byte, 16)

	if _, err := rand.Read(buf); err != nil {
		panic(err.Error())
	}
	return(fmt.Sprintf("%x-%x-%x-%x-%x", buf[0:4], buf[4:6], buf[6:8], buf[8:10], buf[10:]))
}

func createKey() (string) {

	buf := make([]byte, 64) 
	if _, err := rand.Read(buf); err != nil {
		panic(err.Error())
	}
	key := base64.StdEncoding.EncodeToString(buf)

	return(key)
}

func createKeyObject() (AesKey) {
	
	host, _ := os.Hostname()
	event := AesKey{ 
		createUUID(),
		createKey(),
		host, 
		time.Now().Format(time.RFC850)}

	return event
}

func readRequestBody(r *http.Request) (int) {

	var (
		k RequestBody
	)

	b, _ := ioutil.ReadAll(r.Body)
	json.Unmarshal(b, &k)
	return k.NumberOfKeys	
}

func sendEvents(events []*eventhub.Event) (error) {

	var (
		err   error
	)

	ctx, cancel := context.WithTimeout(context.Background(), 20*time.Second)
	defer cancel()

	err = client.SendBatch(ctx, eventhub.NewEventBatchIterator(events...))
	if err != nil {
		return err
	} else {
		return nil 
	}
}

type newAPIHandler struct { }

func (eh *newAPIHandler) getAesKeysHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json; charset=UTF-8")
	keys := "{}"
	json.NewEncoder(w).Encode(keys)
}

func (eh *newAPIHandler) newAesKeyHandler(w http.ResponseWriter, r *http.Request) {
	
	var(
		events  []*eventhub.Event
		aesKeys []AesKey
	)
	
	i := 0
	keysToGenerator := readRequestBody(r)

	for i < keysToGenerator {
		key := createKeyObject()
		aesKeys = append(aesKeys, key)
		encodedAesKey, _ := json.Marshal(key)
		events  = append(events, eventhub.NewEventFromString(string(encodedAesKey)))
		i += 1
	}

	err := sendEvents(events)
	if err != nil {
		fmt.Println(err)
		return
	}

	w.Header().Set("Content-Type", "application/json; charset=UTF-8")
	json.NewEncoder(w).Encode(aesKeys)
}

func (eh *newAPIHandler) optionsHandler(w http.ResponseWriter, r *http.Request) {
	w.WriteHeader(200)
}

func (eh *newAPIHandler) InitHttpServer(port string) {

	var (
		err   	error
		hubName = "events"
	)

	kafkaConStr := os.Getenv("EVENTHUB_CONNECTIONSTRING") + ";EntityPath=" + hubName
	client, err = eventhub.NewHubFromConnectionString(kafkaConStr)

	if err != nil {
		fmt.Println(err)
		return
	}

	r := mux.NewRouter()
	apirouter := r.PathPrefix("/api").Subrouter()
	apirouter.Methods("GET").Path("/keys").HandlerFunc(eh.getAesKeysHandler)
	apirouter.Methods("POST").Path("/keys").HandlerFunc(eh.newAesKeyHandler)
	apirouter.Methods("OPTIONS").Path("/keys").HandlerFunc(eh.optionsHandler)

	server := cors.Default().Handler(r)

	fmt.Print("Listening on ", port)
	log.Fatal(http.ListenAndServe( port , server))
}

func NewAPIHandler() *newAPIHandler {
	return &newAPIHandler{}
}