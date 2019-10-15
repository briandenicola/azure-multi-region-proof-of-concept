package main

import (
	"os"
	"log"
	"internal/aeskeyapi"
)

func main() {
	log.Print("Starting Server . . ")

	port := ":8081"
	if os.Getenv("AES_KEYS_PORT") != "" {
		port = os.Getenv("AES_KEYS_PORT")
	} 

	s := aeskeyapi.NewAPIHandler()
	s.InitHttpServer(port)
}