package aeskeyapi

import (
	"github.com/a8m/documentdb"
)

const (
	EVENT_HUB_NAME 			string = "events"
	COSMOS_DATABASE_NAME 	string = "AesKeys"
	COSMOS_COLLECTION_NAME	string = "Items"
)

//RequestBody - How many Keys to Generate 
type RequestBody struct {
	NumberOfKeys int
}

//AesKey - AESKey Object 
type AesKey struct {
	KeyID 		string	`json:"keyId"`
	Key   		string	`json:"key"`
	ReadHost	string	`json:"readHost"`
	WriteHost 	string	`json:"writeHost"`
	ReadRegion	string	`json:"readRegion"`
	WriteRegion	string	`json:"writeRegion"`
	TimeStamp 	string	`json:"timeStamp"`
}

//Document - AESKey Document Object
type Document struct {
	documentdb.Document
	KeyID 		string	`json:"keyId,omitempty"`
	Key   		string	`json:"key,omitempty"`
	ReadHost	string	`json:"readHost,omitempty"`
	WriteHost 	string	`json:"writeHost,omitempty"`
	ReadRegion	string	`json:"readRegion,omitempty"`
	WriteRegion	string	`json:"writeRegion,omitempty"`
	TimeStamp 	string	`json:"timeStamp,omitempty"`
}

type KeepAlive struct {
	State		string `json:"state"`
}