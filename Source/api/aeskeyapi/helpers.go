package aeskeyapi

import (
	"regexp"
	"crypto/rand"
	"encoding/base64"
	"fmt"
	"os"
	"time"
)

func parseRedisConnectionString(constr string)(string, string) {

	var(
		server 	 string
		password string
		re		 *regexp.Regexp
	)

	re = regexp.MustCompile(`(.*):(\d{4}),`)
	server = re.FindString(constr)
	
	re = regexp.MustCompile(`(password=)(.*=),`)
	password = string(re.FindSubmatch([]byte(constr))[2])

	return server,password

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

func createKeyObject() (*AesKey) {
	
	host, _ := os.Hostname()
	var key = AesKey{ 
		createUUID(),
		createKey(),
		host, 
		time.Now().Format(time.RFC850)}

	return &key

}