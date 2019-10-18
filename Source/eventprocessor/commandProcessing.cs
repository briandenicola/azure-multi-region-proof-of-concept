using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Newtonsoft.Json; 
using Microsoft.Azure.EventHubs;
using Microsoft.Azure.WebJobs;
using Microsoft.Extensions.Logging;
using StackExchange.Redis;

namespace Eventing
{
    public static class CommandProcessing
    {
        private static Lazy<ConnectionMultiplexer> lazyConnection = new Lazy<ConnectionMultiplexer>(() =>
        {
            string cacheConnection =  System.Environment.GetEnvironmentVariable("REDISCACHE_CONNECTIONSTRING");
            return ConnectionMultiplexer.Connect(cacheConnection);
        });

        public static ConnectionMultiplexer Connection
        {
            get
            {
                return lazyConnection.Value;
            }
        }

        [FunctionName("CommandProcessing")]
        public static async Task Run(
            [EventHubTrigger("events", Connection = "EVENTHUB_CONNECTIONSTRING")] EventData[] events,
            [CosmosDB(
                databaseName: "AesKeys", 
                collectionName: "Items", 
                ConnectionStringSetting = "COSMOSDB_CONNECTIONSTRING")] IAsyncCollector<AesKey> keys,
            ILogger log)
        {
            var exceptions = new List<Exception>();         
            IDatabase cache = lazyConnection.Value.GetDatabase();

            foreach (EventData eventData in events)
            {
                try {
                    string messageBody = Encoding.UTF8.GetString(eventData.Body.Array, eventData.Body.Offset, eventData.Body.Count);
                    log.LogInformation($"C# Event Hub trigger function processed a message: {messageBody}");
                    var key = JsonConvert.DeserializeObject<AesKey>(messageBody);

                    var response = cache.StringSet(key.keyId, messageBody);

                    await keys.AddAsync(key);
                    await Task.Yield();
                }
                catch (Exception e) {
                    exceptions.Add(e);
                }
            }
            
            //Bad Bad Bad but need to understand best practices around Redis and Azure Functions disposals()
            //lazyConnection.Value.Dispose();

            if (exceptions.Count > 1)
                throw new AggregateException(exceptions);

            if (exceptions.Count == 1)
                throw exceptions.Single();
        }
    }

    public class AesKey 
    {
        public string keyId { get; set; }
        public string key { get; set; }
        public string host { get; set; }
        public string timeStamp { get; set; }
    }
}
