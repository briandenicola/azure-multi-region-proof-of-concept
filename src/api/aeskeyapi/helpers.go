package aeskeyapi

import (
	"context"
	"crypto/rand"
	"crypto/tls"
	"encoding/base64"
	"encoding/json"
	"errors"
	"fmt"
	"log/slog"
	"os"
	"strings"
	"time"

	"github.com/Azure/azure-sdk-for-go/sdk/azcore"
	"github.com/Azure/azure-sdk-for-go/sdk/azcore/policy"
	"github.com/Azure/azure-sdk-for-go/sdk/azidentity"
	"github.com/Azure/azure-sdk-for-go/sdk/messaging/azeventhubs"
	"github.com/Azure/azure-sdk-for-go/sdk/data/azcosmos"
		
	"github.com/redis/go-redis/v9"
)

func handleCosmosDBAuthentication(CosmosConnectionString string, DatabaseName string, ContainerName string, logger *slog.Logger) (*azcosmos.Client, *azcosmos.ContainerClient, error) {
	var (
		err error
		cosmosClient *azcosmos.Client
		cosmosDatabase *azcosmos.DatabaseClient
		cosmosContainer *azcosmos.ContainerClient	
	)
	
	clientOptions := azcosmos.ClientOptions{
		EnableContentResponseOnWrite: true,
	}

	logger.Info("DB Setup and Authentication", "Cosmos Connection String", CosmosConnectionString)

	cosmosClient, err = azcosmos.NewClientFromConnectionString(CosmosConnectionString, &clientOptions)
	if err != nil {
		return nil, nil, err
	}

	cosmosDatabase, err = cosmosClient.NewDatabase(DatabaseName)
	if err != nil {
		return nil, nil, err
	}


	cosmosContainer, err = cosmosDatabase.NewContainer(ContainerName)
	if err != nil {
		return nil, nil, err
	}

	return cosmosClient, cosmosContainer, nil
}

func handleEventHubAuthentication(EventHubUri string, EventHub string, ClientId string, logger *slog.Logger) (*azeventhubs.ProducerClient, error) {

	managed, _ := azidentity.NewManagedIdentityCredential(&azidentity.ManagedIdentityCredentialOptions{
		ID: azidentity.ClientID(ClientId),
	})

	azCLI, _ := azidentity.NewAzureCLICredential(nil)
	credChain, _ := azidentity.NewChainedTokenCredential([]azcore.TokenCredential{managed, azCLI}, nil)

	producerClient, err := azeventhubs.NewProducerClient(EventHubUri, EventHub, credChain, nil)

	if err != nil {
		logger.Error("Event Hubs", "Error", "Error Connecting to Redis Cache")
	}

	return producerClient, err
}

func handleRedisAuthentication(RedisUri string, ClientId string, logger *slog.Logger) (*redis.Client, bool) {

	var cacheEnabled = false

	managed, _ := azidentity.NewManagedIdentityCredential(&azidentity.ManagedIdentityCredentialOptions{
		ID: azidentity.ClientID(ClientId),
	})

	azCLI, _ := azidentity.NewAzureCLICredential(nil)
	credChain, err := azidentity.NewChainedTokenCredential([]azcore.TokenCredential{managed, azCLI}, nil)

	if err != nil {
		logger.Error("Redis Cache", "Error", "Error creating token credential")
		return nil, false
	}

	redisClient := redis.NewClient(&redis.Options{
		Addr:                       RedisUri,
		CredentialsProviderContext: redisCredentialProvider(credChain),
		TLSConfig:                  &tls.Config{MinVersion: tls.VersionTLS12},
	})

	if redisClient == nil {
		logger.Error("Redis Cache", "Error", "Error creating connection to Redis Cache")
		cacheEnabled = false
	}

	return redisClient, cacheEnabled
}

func redisCredentialProvider(credential azcore.TokenCredential) func(context.Context) (string, string, error) {
	
	return func(ctx context.Context) (string, string, error) {

		tk, err := credential.GetToken(ctx, policy.TokenRequestOptions{
			Scopes: []string{"https://redis.azure.com/.default"},
		})
		
		if err != nil {
			return "", "", err
		}

		parts := strings.Split(tk.Token, ".")
		if len(parts) != 3 {		
			return "", "", errors.New("token must have 3 parts")
		}

		payload, err := base64.RawURLEncoding.DecodeString(parts[1])
		if err != nil {
			return "", "", fmt.Errorf("couldn't decode payload: %s", err)
		}

		claims := struct {
			OID string `json:"oid"`
		}{}

		err = json.Unmarshal(payload, &claims)
		if err != nil {
			return "", "", fmt.Errorf("couldn't unmarshal payload: %s", err)
		}

		if claims.OID == "" {
			return "", "", errors.New("missing object ID claim")
		}

		return claims.OID, tk.Token, nil
	}
}

func encodeForEventHub(data *AesKey) azeventhubs.EventData {
	encoded, _ := json.Marshal(data)
	return azeventhubs.EventData{
		Body: encoded,
	}
}

func createUUID() string {
	buf := make([]byte, 16)

	if _, err := rand.Read(buf); err != nil {
		panic(err.Error())
	}

	return fmt.Sprintf("%x-%x-%x-%x-%x", buf[0:4], buf[4:6], buf[6:8], buf[8:10], buf[10:])
}

func createKey() string {
	buf := make([]byte, 64)
	if _, err := rand.Read(buf); err != nil {
		panic(err.Error())
	}
	key := base64.StdEncoding.EncodeToString(buf)

	return key
}

func NewAesKey() *AesKey {
	var key = AesKey{
		createUUID(),
		COSMOS_PARTITION_KEY_VALUE,
		createKey(),
		false,
		getEmptyString(),
		getHost(),
		getEmptyString(),
		getRegion(),
		time.Now().Format(time.RFC850)}

	return &key
}

func getRegion() string {
	return os.Getenv("REGION")
}

func getHost() string {
	host, _ := os.Hostname()
	return host
}

func getEmptyString() string {
	return ""
}
