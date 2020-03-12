package aeskeyapi

import (
	"encoding/json"
	"net/http"
	"log"
	"os"
	"time"
	"io/ioutil"
	"strconv"
	"github.com/gorilla/mux"
	"github.com/rs/cors"
	"github.com/microsoft/ApplicationInsights-Go/appinsights"
)

//API Interface
type API interface { 
	InitHTTPServer(port string)
	GetID(r *http.Request) 
	Get(w http.ResponseWriter, r *http.Request) 
	Post(w http.ResponseWriter, r *http.Request)
	Options(w http.ResponseWriter, r *http.Request)
	parseRequestBody(r *http.Request) int
	writeRequestReply(w http.ResponseWriter, args ...interface{}) 
	logRequest(handler http.Handler) http.Handler 
	errorHandler(err error)
}

//AESApi Structre
type AESApi struct {
	keydb  		*AESKeyDB
	aiClient	appinsights.TelemetryClient
}

//NewKeyAPI - Initialized KeyDB
func NewKeyAPI() (*AESApi) {
	api := new(AESApi)

	api.aiClient = appinsights.NewTelemetryClient( os.Getenv("APPINSIGHTS_INSTRUMENTATIONKEY") )
	api.aiClient.Track(appinsights.NewTraceTelemetry("Setup of AI client complete...", appinsights.Information ))

	api.keydb, _ = NewKeysDB()
	api.aiClient.Track(appinsights.NewTraceTelemetry("Setup of Database Connections complete...", appinsights.Information ))
	
	return api
}

//InitHTTPServer - Initialized HTTP Server
func (a *AESApi) InitHTTPServer(port string) {

	r := mux.NewRouter()
	apirouter := r.PathPrefix("/api").Subrouter()
	apirouter.Methods("GET").Path("/keys/{id}").HandlerFunc(a.Get)
	apirouter.Methods("POST").Path("/keys").HandlerFunc(a.Post)
	apirouter.Methods("OPTIONS").Path("/keys").HandlerFunc(a.Options)
	
	r.HandleFunc("/healthz", func(w http.ResponseWriter, r *http.Request) {
		a.writeRequestReply(w, KeepAlive{State: "I'm alive!"} )
	})

	server := cors.Default().Handler(r)

	log.Print("Listening on ", port)
	log.Fatal(http.ListenAndServe( port , a.logRequest(server)))
}

//logRequest - Write requets to stdout
func (a *AESApi) logRequest (handler http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		log.Printf("%s %s %s\n", r.RemoteAddr, r.Method, r.URL)
		
		startTime := time.Now()
		handler.ServeHTTP(w, r)
		duration := time.Now().Sub(startTime)

		trace := appinsights.NewRequestTelemetry(r.Method, r.URL.Path, duration, strconv.Itoa(http.StatusOK) )
        trace.Timestamp = time.Now()
        a.aiClient.Track(trace)
	})
}

func (a *AESApi) errorHandler(err error) {
	if err != nil {
		log.Printf("Error - %s", err)
        trace := appinsights.NewTraceTelemetry(err.Error(), appinsights.Error)
        trace.Timestamp = time.Now()
        a.aiClient.Track(trace)
        defer appinsights.TrackPanic(a.aiClient, false)
	}
}

//parseRequestBody - Parse JSON body
func (a *AESApi) parseRequestBody(r *http.Request) (int) {
	var k RequestBody
	
	b, _ := ioutil.ReadAll(r.Body)
	err := json.Unmarshal(b, &k)

	if err != nil {
		return 0
	}
	return k.NumberOfKeys	
}


//writeRequestReply - Write JSON Reply
func (a *AESApi) writeRequestReply(w http.ResponseWriter, args ...interface{}) {
	w.Header().Set("Content-Type", "application/json; charset=UTF-8")
	json.NewEncoder(w).Encode(args)
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
	key, err := a.keydb.Get(id)

	if err != nil {
		a.writeRequestReply(w, err)
		a.errorHandler(err)
		return
	}

	if key != nil {
		key.ReadRegion = getRegion()
		key.ReadHost = getHost()
	}

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
	savedKeys, err := a.keydb.Save()

	if err != nil {
		a.errorHandler(err)
		a.writeRequestReply(w, err)
	}

	a.keydb.Flush()
	a.writeRequestReply(w, savedKeys)
}