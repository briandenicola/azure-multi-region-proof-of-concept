using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Newtonsoft.Json; 
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Host;
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
                key.Id = Guid.NewGuid();

                log.LogInformation($"Adding {key} to Cosmosdb Collection");
                await keys.AddAsync(key);
            }

        }
    }

    public class AesKey 
    {
        public string Id { get; set; }
        public string KeyId { get; set; }
        public string Key { get; set; }
        public string ReadHost  { get; set; }
        public string WriteHost  { get; set; }
        public string readRegion  { get; set; }
        public string writeRegion  { get; set; }
        public string timeStamp { get; set; }
    }
}
