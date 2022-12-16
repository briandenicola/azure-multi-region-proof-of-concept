package main

import (
	"github.com/bjd145/cqrs/aeskeyapi"
	"log"
	"os"
)

func main() {
	log.Print("Starting Server . . ")

	port := ":8080"
	if os.Getenv("AES_KEYS_PORT") != "" {
		port = os.Getenv("AES_KEYS_PORT")
	}

	s := aeskeyapi.NewKeyAPI()
	s.InitHTTPServer(port)
}
