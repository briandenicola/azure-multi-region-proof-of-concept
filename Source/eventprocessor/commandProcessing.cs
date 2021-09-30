using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Newtonsoft.Json; 
using Microsoft.Azure.EventHubs;
using Microsoft.Azure.WebJobs;
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
                collectionName: "Items", 
                ConnectionStringSetting = "COSMOSDB_CONNECTIONSTRING")] IAsyncCollector<AesKey> keys,
            ILogger log)
        {
            var exceptions = new List<Exception>();         

            foreach (EventData eventData in events)
            {
                try {
                    string messageBody = Encoding.UTF8.GetString(eventData.Body.Array, eventData.Body.Offset, eventData.Body.Count);
                    log.LogInformation($"C# Event Hub trigger function processed a message: {messageBody}");
                    var key = JsonConvert.DeserializeObject<AesKey>(messageBody);

                    await keys.AddAsync(key);
                    await Task.Yield();        
                }
                catch (Exception e) {
                    exceptions.Add(e);
                }
            }

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
        public string readHost  { get; set; }
        public string writeHost  { get; set; }
        public string readRegion  { get; set; }
        public string writeRegion  { get; set; }
        public string timeStamp { get; set; }
    }
}
