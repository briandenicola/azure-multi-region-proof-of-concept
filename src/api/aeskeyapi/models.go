package aeskeyapi

import (
//"github.com/a8m/documentdb"
)

const (
	EVENT_HUB_NAME         string = "events"
	COSMOS_DATABASE_NAME   string = "AesKeys"
	COSMOS_COLLECTION_NAME string = "Items"
)

//RequestBody - How many Keys to Generate
type RequestBody struct {
	NumberOfKeys int
}

//AesKey - AESKey Object
type AesKey struct {
	KeyID       string `json:"keyId"`
	Key         string `json:"key"`
	FromCache   bool   `json:"fromCache"`
	ReadHost    string `json:"readHost"`
	WriteHost   string `json:"writeHost"`
	ReadRegion  string `json:"readRegion"`
	WriteRegion string `json:"writeRegion"`
	TimeStamp   string `json:"timeStamp"`
}