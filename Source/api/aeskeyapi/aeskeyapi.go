package aeskeyapi

import (
	"encoding/json"
	"net/http"
	"fmt"
	"log"
	"io/ioutil"
	"github.com/gorilla/mux"
	"github.com/rs/cors"
)

//API Interface
type API interface { 
	InitHTTPServer(port string)
	GetID(r *http.Request) 
	Get(w http.ResponseWriter, r *http.Request) 
	Post(w http.ResponseWriter, r *http.Request)
	Options(w http.ResponseWriter, r *http.Request)
	parseRequestBody(r *http.Request) int
	writeRequestReply(w http.ResponseWriter, r *http.Request, keys []*AesKey)
}

//AESApi Structre
type AESApi struct {
	keydb  *AESKeyDB
}

//NewKeyAPI - Initialized KeyDB
func NewKeyAPI() (*AESApi) {
	api := new(AESApi)
	api.keydb, _ = NewKeysDB()
	return api
}

//InitHTTPServer - Initialized HTTP Server
func (a *AESApi) InitHTTPServer(port string) {

	r := mux.NewRouter()
	apirouter := r.PathPrefix("/api").Subrouter()
	apirouter.Methods("GET").Path("/keys/{id}").HandlerFunc(a.Get)
	apirouter.Methods("POST").Path("/keys").HandlerFunc(a.Post)
	apirouter.Methods("OPTIONS").Path("/keys").HandlerFunc(a.Options)

	server := cors.Default().Handler(r)

	fmt.Print("Listening on ", port)
	log.Fatal(http.ListenAndServe( port , server))
}

//parseRequestBody - Parse JSON body
func (a *AESApi) parseRequestBody(r *http.Request) (int) {
	var k RequestBody
	
	b, _ := ioutil.ReadAll(r.Body)
	json.Unmarshal(b, &k)
	return k.NumberOfKeys	
}

//writeRequestReply - Write JSON Reply
func (a *AESApi) writeRequestReply(w http.ResponseWriter, keys []*AesKey) {
	w.Header().Set("Content-Type", "application/json; charset=UTF-8")
	json.NewEncoder(w).Encode(keys)
}

//Options - HTTP Options Handler 
func (a *AESApi) Options(w http.ResponseWriter, r *http.Request) {
	w.WriteHeader(200)
}

//GetID - HTTP GET Path handler
func (a *AESApi) GetID(r *http.Request) (string) {
	vars := mux.Vars(r)
	return vars["id"]
}

//Get - HTTP GET Handler 
func (a *AESApi) Get(w http.ResponseWriter, r *http.Request) {
	id := a.GetID(r)
	key, _ := a.keydb.Get(id)
	a.writeRequestReply(w, []*AesKey{key})
}

//Post - HTTP POST Handler 
func (a *AESApi) Post(w http.ResponseWriter, r *http.Request) {
	keysToGenerator := a.parseRequestBody(r)

	i := 0
	for i < keysToGenerator {
		key := NewAesKey()
		a.keydb.Add(key)
		i++
	}
	savedKeys, _ := a.keydb.Save()
	a.keydb.Flush()

	a.writeRequestReply(w, savedKeys)
}