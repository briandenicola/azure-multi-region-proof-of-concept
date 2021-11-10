using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Newtonsoft.Json; 
using Microsoft.Azure.WebJobs;
using Azure.Messaging.EventHubs;
using Microsoft.Extensions.Logging;


namespace Eventing
{
    public static class CommandProcessing
    {
        [FunctionName("CommandProcessing")]
        public static async Task Run(
        
            [EventHubTrigger(
                "events", 
                Connection = "EVENTHUB_CONNECTIONSTRING")] EventData[] events,
            [CosmosDB(
                databaseName: "AesKeys", 
                containerName: "Items", 
                Connection = "COSMOSDB_CONNECTIONSTRING")] IAsyncCollector<AesKey> keys,
            ILogger log)
        {
            foreach (var e in events)
            {
                log.LogInformation($"C# function triggered to process a message: {e.EventBody}");
                string messageBody = Encoding.UTF8.GetString(e.EventBody);
                var key = JsonConvert.DeserializeObject<AesKey>(messageBody);
                await keys.AddAsync(key);
                await Task.Yield();
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
