using System;
using System.Threading.Tasks;
using System.Collections.Generic;
using Newtonsoft.Json; 
using Microsoft.Extensions.Logging;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Azure.Functions.Worker.Extensions.Redis; 

public class ChangeFeedProcessor
{
    private readonly ILogger<ChangeFeedProcessor> logger;

    public ChangeFeedProcessor(ILogger<ChangeFeedProcessor> logger)
    {
        this.logger = logger;
    }

    [Function("CosmosChangeFeedProcessor")]
    [RedisOutput(Common.redisConnectionString, "SET")] 

    public static async Task<String> CosmosChangeFeedProcessor (
        [CosmosDBTrigger(
            databaseName: Common.cosmosdbDatabase, 
            containerName: Common.cosmosdbContainer, 
            Connection  = Common.cosmosdbConnectionString,
            LeaseContainerName   =  "leases",
            LeaseContainerPrefix = "LEASE_COLLECTION_PREFIX",
            CreateLeaseContainerIfNotExists = true
        )]IReadOnlyList<AesKey> changeStream,
        FunctionContext context)
    {

        var logger = context.GetLogger("CosmosChangeFeedProcessor");

        if( Convert.ToBoolean(System.Environment.GetEnvironmentVariable("CACHE_ENABLED") ) ) {
            if (changeStream != null && changeStream.Count > 0) {
                try {
                    logger.LogInformation($"{changeStream.Count} - Documents will be added to Cache");

                    foreach( var key in changeStream ) 
                    {                       
                        var redisItem = new AesKey(){
                            keyId = key.keyId,
                            key = JsonConvert.SerializeObject(key)
                        };
                        var redisItemSerialized = JsonConvert.SerializeObject(redisItem);

                        logger.LogInformation($"Key: \"{key.keyId}\", Value: \"{redisItemSerialized}\" added to Cache");
                        return $"{key.keyId} {redisItemSerialized}";
                    }
                }
                catch( Exception e ) {
                    logger.LogInformation($"Failed to index some of the documents: {e.ToString()}");
                }
            }
        }
        return null;
    }
}