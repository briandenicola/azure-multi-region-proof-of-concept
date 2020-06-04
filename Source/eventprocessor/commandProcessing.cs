using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Newtonsoft.Json; 
using Microsoft.Azure.EventHubs;
using Microsoft.Azure.WebJobs;
using Microsoft.Extensions.Logging;
using Microsoft.Azure.Search;
using Microsoft.Azure.Search.Models;
                                
namespace Eventing
{
    public static class CommandProcessing
    {
        private static string searchServiceName = Environment.GetEnvironmentVariable("SEARCH_SERVICENAME", EnvironmentVariableTarget.Process);
        private static string searchAdminKey    = Environment.GetEnvironmentVariable("SEARCH_ADMINKEY", EnvironmentVariableTarget.Process);
        private static string searchIndexName   = Environment.GetEnvironmentVariable("SEARCH_INDEXNAME", EnvironmentVariableTarget.Process);

        private static SearchServiceClient serviceClient = new SearchServiceClient(
            searchServiceName, 
            new SearchCredentials(searchAdminKey)
        );

        [FunctionName("CommandProcessing")]
        public static async Task Run(
            [EventHubTrigger( "events", 
                Connection = "EVENTHUB_CONNECTIONSTRING")] EventData[] events,
            ILogger log)
        {
            var exceptions = new List<Exception>();         
            var indexClient = serviceClient.Indexes.GetClient(searchIndexName);

            var data = events.Select( eventData => 
                JsonConvert.DeserializeObject<AesKey>(Encoding.UTF8.GetString(eventData.Body.Array, eventData.Body.Offset, eventData.Body.Count))
            );
            
            var batch = IndexBatch.MergeOrUpload<AesKey>(data);
            indexClient.Documents.Index(batch);

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
