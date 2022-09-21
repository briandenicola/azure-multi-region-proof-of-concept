package aeskeyapi

import (
	"regexp"
	"crypto/rand"
	"encoding/base64"
	"fmt"
	"os"
	"time"
)

func parseEventHubConnectionString(constr string)(string) {
	return constr
}

func parseRedisConnectionString(constr string)(string, string) {
	var(
		server 	 string
		password string
		re		 *regexp.Regexp
	)

	re = regexp.MustCompile(`(.*):(\d{4})`)
	server = re.FindString(constr)
	
	re = regexp.MustCompile(`(password=)(.*=),`)
	password = string(re.FindSubmatch([]byte(constr))[2])

	return server,password
}

func parseCosmosConnectionString(constr string)(string, string) {
	var(
		account	 	string
		masterKey	string
		re		 	*regexp.Regexp
	)

	re = regexp.MustCompile(`(AccountEndpoint=)(.*:\d{3})`)
	account = string(re.FindSubmatch([]byte(constr))[2])
	
	re = regexp.MustCompile(`(AccountKey=)(.*);`)
	masterKey = string(re.FindSubmatch([]byte(constr))[2])

	return account,masterKey
}

func createUUID() (string) {
	buf := make([]byte, 16)

	if _, err := rand.Read(buf); err != nil {
		panic(err.Error())
	}

	return fmt.Sprintf("%x-%x-%x-%x-%x", buf[0:4], buf[4:6], buf[6:8], buf[8:10], buf[10:])
}

func createKey() (string) {
	buf := make([]byte, 64) 
	if _, err := rand.Read(buf); err != nil {
		panic(err.Error())
	}
	key := base64.StdEncoding.EncodeToString(buf)

	return key 
}

func NewAesKey() (*AesKey) {
	var key = AesKey{ 
		createUUID(),
		createKey(),
		false,
		getEmptyString(),
		getHost(),
		getEmptyString(),
		getRegion(),
		time.Now().Format(time.RFC850)}

	return &key
}

func getRegion() (string) {
	return os.Getenv("REGION")
}

func getHost() (string) {
	host, _ := os.Hostname()
	return host
}

func getEmptyString() (string) {
	return ""
}