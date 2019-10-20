package aeskeyapi

type RequestBody struct {
	NumberOfKeys int
}

type AesKey struct {
	KeyId 		string	`json:"keyId"`
	Key   		string	`json:"key"`
	Host  		string	`json:"host"`
	TimeStamp 	string	`json:"timeStamp"`
}
