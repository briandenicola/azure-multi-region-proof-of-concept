package aeskeyapi

import (
	"encoding/json"
	"math/rand"
	"io/ioutil"
	"time"
	"os"
	"net/http"
	"encoding/base64"
	"fmt"
	"log"
	"github.com/gorilla/mux"
	"github.com/rs/cors"
)

type KeyAmount struct {
	NumberOfKeys int
}

type Random struct {
	Time string
    Host string
	Number int
	AesKey string
}

func createKey() (string) {
	key := make([]byte, 64) 
	if _, err := rand.Read(key); err != nil {
		panic(err.Error())
	}
	return(base64.StdEncoding.EncodeToString(key))
}

func createMessage() (Random) {
	rand.Seed(time.Now().UTC().UnixNano())
	max := 1000
	min := 0
	host, _ := os.Hostname()
	msg := Random{ 
		time.Now().Format(time.RFC850), 
		host, 
		rand.Intn(max-min),
		createKey()}
	return msg
}

func generateRandomKeys(len int) []Random {
	keys := []Random{createMessage()}

	i := 0
	for i < (len-1) {
		keys = append(keys, createMessage())
		i += 1
	}
	return keys
}

type newAPIHandler struct { }

func (eh *newAPIHandler) getAesKeysHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json; charset=UTF-8")
	len := 1
	keys := generateRandomKeys(len)
	json.NewEncoder(w).Encode(keys)
}

func (eh *newAPIHandler) newAesKeyHandler(w http.ResponseWriter, r *http.Request) {
	var k KeyAmount
	b, _ := ioutil.ReadAll(r.Body)
	json.Unmarshal(b, &k)

	w.Header().Set("Content-Type", "application/json; charset=UTF-8")
	keys := generateRandomKeys(k.NumberOfKeys)
	fmt.Println("Number of Keys - ", k.NumberOfKeys)
	json.NewEncoder(w).Encode(keys)
}

func (eh *newAPIHandler) optionsHandler(w http.ResponseWriter, r *http.Request) {
	w.WriteHeader(200)
}

func (eh *newAPIHandler) InitHttpServer(port string) {
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