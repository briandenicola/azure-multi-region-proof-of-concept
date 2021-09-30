using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Newtonsoft.Json; 
using Microsoft.Azure.WebJobs;
using Microsoft.Extensions.Logging;
using Fbeltrao.AzureFunctionExtensions;
using StackExchange.Redis;

namespace Eventing
{
    public static class ChangeFeedProcessor
    {
        [FunctionName("CosmosChangeFeedProcessor")]
        public static async Task Run (
            [CosmosDBTrigger(
                databaseName: "AesKeys", 
                collectionName: "Items", 
                ConnectionStringSetting = "COSMOSDB_CONNECTIONSTRING",
                LeaseCollectionName =  "leases",
                LeaseCollectionPrefix = "blob",
                CreateLeaseCollectionIfNotExists = true
            )]IReadOnlyList<Microsoft.Azure.Documents.Document> changeStream,  
            
            [RedisOutput(
                Connection = "%REDISCACHE_CONNECTIONSTRING%"
            )] IAsyncCollector<RedisOutput> cacheKeys,                
            
            ILogger log)
        {
            if (changeStream == null || changeStream.Count <= 0) {
                log.LogInformation($"CosmosChangeFeedProcessor - Fired but inputStream is null");
                return;
            }

            try {
                log.LogInformation($"{changeStream.Count} - Documents will be added to Cache");

                foreach( var document in changeStream ) 
                {
                    var key = (AesKey)(dynamic)document;
                    
                    var redisItem = new RedisOutput(){
                        Key = key.keyId,
                        TextValue = JsonConvert.SerializeObject(key)
                    };
                    await cacheKeys.AddAsync(redisItem);
                }
            }
            catch( Exception e ) {
                log.LogInformation($"Failed to index some of the documents: {e.ToString()}");
            }
        }
    }

    public class AesKey 
    {
        public string keyId { get; set; }
        public string key { get; set; }
        public string readHost  { get; set; }
        public string writeHost  { get; set; }
        public string readRegion  { get; set; }
        public string writeRegion  { get; set; }
        public string timeStamp { get; set; }
    }
}
