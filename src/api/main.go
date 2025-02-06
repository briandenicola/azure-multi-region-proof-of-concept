package main

import (
	"github.com/briandenicola/azure-multi-region-proof-of-concept/aeskeyapi"
	"log/slog"
	"os"
)

func main() {
	port := ":8080"
	if os.Getenv("AES_KEYS_PORT") != "" {
		port = os.Getenv("AES_KEYS_PORT")
	}

	jsonHandler := slog.NewJSONHandler(os.Stderr, nil)
	slogger := slog.New(jsonHandler)

	slogger.Info("Starting Server", "port", port)
	s := aeskeyapi.NewKeyAPI()
	s.InitHTTPServer(port)
}
