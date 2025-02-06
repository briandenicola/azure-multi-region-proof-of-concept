using System;
using System.Threading.Tasks;
using Newtonsoft.Json;
using Microsoft.Azure.WebJobs;
using Microsoft.Extensions.Logging;
using Azure.Messaging.EventHubs;

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
                containerName: "Items",
                Connection  = "COSMOSDB_CONNECTIONSTRING")] IAsyncCollector<AesKey> keys,
            ILogger log)
        {
            foreach (EventData eventData in events)
            {
                log.LogInformation($"C# Event Hub trigger function processed a message: {eventData.EventBody}");
                var item = new AesKey();
                item.Id = Guid.NewGuid().ToString();
                item.Key = System.Text.Encoding.UTF8.GetString(eventData.EventBody);
                await keys.AddAsync(item);

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

        [JsonProperty("fromCache")]
        public bool FromCache { get; set; }

        [JsonProperty("readHost")]
        public string ReadHost { get; set; }

        [JsonProperty("writeHost")]
        public string WriteHost { get; set; }

        [JsonProperty("readRegion")]
        public string ReadRegion { get; set; }

        [JsonProperty("writeRegion")]
        public string WriteRegion { get; set; }

        [JsonProperty("timeStamp")]
        public string TimeStamp { get; set; }

        public AesKey()
        {
            Id = Guid.NewGuid().ToString();
        }
    }
}
