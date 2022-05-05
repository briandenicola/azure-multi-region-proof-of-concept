using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Newtonsoft.Json; 
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Host;
using Microsoft.Azure.EventHubs;
using Microsoft.Extensions.Logging;


namespace Eventing
{
    public static class CommandProcessing
    {
        [FunctionName("CommandProcessing")]
        public static async Task Run(
        
            [EventHubTrigger(
                "events",
                ConsumerGroup =  "eventsfunction",
                Connection = "EVENTHUB_CONNECTIONSTRING")] EventData[] events,
            [CosmosDB(
                databaseName: "AesKeys", 
                collectionName: "Items", 
                ConnectionStringSetting  = "COSMOSDB_CONNECTIONSTRING")] IAsyncCollector<AesKey> keys,
            ILogger log)
        {
            foreach (var e in events)
            {
                string messageBody = Encoding.UTF8.GetString(e.Body.Array, e.Body.Offset, e.Body.Count);
                log.LogInformation($"C# Event Hub trigger function processed a message: {messageBody}");
                var key = JsonConvert.DeserializeObject<AesKey>(messageBody);
                
                key.Id = Guid.NewGuid().ToString(); 

                log.LogInformation($"Adding key ({key.Id}) to Cosmosdb Collection");
                await keys.AddAsync(key);

            }

        }
    }

    public class AesKey 
    {
        [JsonProperty("id")]   
        public string Id { get; set; }

        [JsonProperty("keyId")]
        public string KeyId { get; set; }

        [JsonProperty("key")]
        public string Key { get; set; }

        [JsonProperty("readHost")]
        public string ReadHost  { get; set; }

        [JsonProperty("writeHost")]
        public string WriteHost  { get; set; }

        [JsonProperty("readRegion")]
        public string ReadRegion  { get; set; }

        [JsonProperty("writeRegion")]
        public string WriteRegion  { get; set; }

        [JsonProperty("timeStamp")]
        public string TimeStamp { get; set; }

		public AesKey() {
			Id = Guid.NewGuid().ToString();
		}
    }
}
