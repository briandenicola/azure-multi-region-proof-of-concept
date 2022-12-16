package aeskeyapi

import (
	"fmt"
	"github.com/gin-gonic/gin"
	"github.com/gin-contrib/cors"
	"github.com/microsoft/ApplicationInsights-Go/appinsights"
	"log"
	"net/http"
	"os"
	"time"
)

//API Interface
type API interface {
	InitHTTPServer(port string)
	GetById(c *gin.Context)
	NotImplemented(c *gin.Context)
	Post(c *gin.Context)
	Options(c *gin.Context)
	ParseRequestBody(c *gin.Context) int
	CustomLogger(param gin.LogFormatterParams) string
	AppInsightsTracer() gin.HandlerFunc 
	LogErrorHandler(err error)
}

//AESApi Structre
type AESApi struct {
	keydb    *AESKeyDB
	aiClient appinsights.TelemetryClient
}

//NewKeyAPI - Initialized KeyDB
func NewKeyAPI() *AESApi {
	api := new(AESApi)

	api.aiClient = appinsights.NewTelemetryClient(os.Getenv("APPINSIGHTS_INSTRUMENTATIONKEY"))
	api.aiClient.Track(appinsights.NewTraceTelemetry("Setup of AI client complete...", appinsights.Information))

	api.keydb, _ = NewKeysDB()
	api.aiClient.Track(appinsights.NewTraceTelemetry("Setup of Database Connections complete...", appinsights.Information))

	return api
}

//InitHTTPServer - Initialized HTTP Server
func (a *AESApi) InitHTTPServer(port string) {

	router := gin.New()
	router.SetTrustedProxies(nil)
	router.Use(gin.LoggerWithFormatter(a.CustomLogger))
	router.Use(a.AppInsightsTracer())
	router.Use(cors.Default())
	router.Use(gin.Recovery())

	apirouter := router.Group("/api")
	apirouter.GET("/keys/:id", a.GetById)
	apirouter.POST("/keys",a.Post)
	apirouter.OPTIONS("/keys", a.Options)
	apirouter.GET("/keys", a.NotImplemented)
	apirouter.DELETE("/keys/:id", a.NotImplemented)
	apirouter.PUT("/keys/:id", a.NotImplemented)
	
	router.GET("/healthz", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{"state": "I'm alive!"})
	})

	log.Print("Listening on ", port)
	log.Fatal(router.Run(port))
}

func (a *AESApi) CustomLogger(param gin.LogFormatterParams) string {

	return fmt.Sprintf("%s - [%s] %s %s %s %d %s %s\n",
		param.ClientIP,
		param.TimeStamp.Format(time.RFC1123),
		param.Method,
		param.Path,
		param.Request.Proto,
		param.StatusCode,
		param.Request.UserAgent(),
		param.ErrorMessage,
	)
}

func (a *AESApi) AppInsightsTracer() gin.HandlerFunc {

	return func(c *gin.Context) {

		startTime := time.Now()
		c.Next()
		duration := time.Since(startTime)

		trace := appinsights.NewRequestTelemetry(c.Request.Method, c.FullPath(), duration, "200")
		trace.Id = c.GetHeader("Correlation-Id")
		trace.Properties["X-FORWARDED-FOR"] = c.GetHeader("X-FORWARDED-FOR")
		trace.Timestamp = time.Now()
		a.aiClient.Track(trace)
	}
}

func (a *AESApi) LogErrorHandler(c *gin.Context, err error) {

	if err != nil {
		log.Printf("Error - %s", err)
		trace := appinsights.NewTraceTelemetry(err.Error(), appinsights.Error)
		trace.Timestamp = time.Now()
		a.aiClient.Track(trace)
		defer appinsights.TrackPanic(a.aiClient, false)
	}

	c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
}

func (a *AESApi) ParseRequestBody(c *gin.Context) int {

	var json RequestBody

	if c.BindJSON(&json) == nil {
		return json.NumberOfKeys
	}

	return 0
}

//Options - HTTP Options Handler
func (a *AESApi) Options(c *gin.Context) {
	c.String(http.StatusOK, "pong")
}

func (a *AESApi) NotImplemented(c *gin.Context) {
	c.String(http.StatusNotImplemented, "")
}

//GetbyId - HTTP GET Handler
func (a *AESApi) GetById(c *gin.Context) {

	id := c.Param("id")
	key, err := a.keydb.Get(id)

	if err != nil {
		a.LogErrorHandler(c, err)
		return
	}

	if key != nil {
		key.ReadRegion = getRegion()
		key.ReadHost = getHost()
	}

	c.JSON(http.StatusOK, key)
}

//Post - HTTP POST Handler
func (a *AESApi) Post(c *gin.Context) {
	
	keysToGenerator := a.ParseRequestBody(c)

	log.Printf("Keys to generate - %d", keysToGenerator)

	i := 0
	for i < keysToGenerator {
		key := NewAesKey()
		a.keydb.Add(key)
		i++
	}

	savedKeys, err := a.keydb.Save()
	if err != nil {
		a.LogErrorHandler(c,err)
		return
	}

	a.keydb.Flush()
	c.JSON(http.StatusOK, savedKeys)
}
