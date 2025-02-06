using System;
using System.Collections.Generic;
using Newtonsoft.Json; 
using Microsoft.Azure.WebJobs;
using Microsoft.Extensions.Logging;
using Microsoft.Azure.Functions.Worker.Extensions.Redis; 
using Microsoft.Azure.WebJobs.Extensions.Redis;
namespace Eventing
{
    public static class ChangeFeedProcessor
    {
        [FunctionName("CosmosChangeFeedProcessor")]
        [RedisOutput("redisConnectionString", "SET")]   
        public static string Run (
            [CosmosDBTrigger(
                databaseName: "AesKeys", 
                containerName: "Items", 
                Connection  = "COSMOSDB_CONNECTIONSTRING",
                LeaseContainerName   =  "leases",
                LeaseContainerPrefix = "LEASE_COLLECTION_PREFIX",
                CreateLeaseContainerIfNotExists = true
            )]IReadOnlyList<AesKey> changeStream,  
            ILogger log)
        {
            if (changeStream != null && changeStream.Count > 0) {
                try {
                    log.LogInformation($"{changeStream.Count} - Documents will be added to Cache");

                    foreach( var key in changeStream ) 
                    {                       
                        var redisItem = new AesKey(){
                            keyId = key.keyId,
                            key = JsonConvert.SerializeObject(key)
                        };
                       return JsonConvert.SerializeObject(redisItem);
                    }
                }
                catch( Exception e ) {
                    log.LogInformation($"Failed to index some of the documents: {e.ToString()}");
                }
            }

            return null;
        }
    }

    public class AesKey 
    {
        public string keyId { get; set; }
        public string key { get; set; }

        public bool fromCache  { get; set; }
        public string readHost  { get; set; }
        public string writeHost  { get; set; }
        public string readRegion  { get; set; }
        public string writeRegion  { get; set; }
        public string timeStamp { get; set; }
    }
}
