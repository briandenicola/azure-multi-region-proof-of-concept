using System;
using Microsoft.Azure.Search;
using Microsoft.Azure.Search.Models;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Configuration.Json;

namespace searchindexapp
{
    class Program
    {
        static void Main(string[] args)
        {
            IConfigurationBuilder builder = new ConfigurationBuilder().AddJsonFile("appsettings.json");
            IConfigurationRoot configuration = builder.Build();

            SearchServiceClient serviceClient = CreateSearchServiceClient(configuration);

            string indexName = configuration["SearchIndexName"];

            Console.WriteLine("Delelting index - {0}...\n", indexName);
            DeleteIndexIfExists(indexName, serviceClient);

            Console.WriteLine("Creating index - {0}...\n", indexName);
            CreateIndex(indexName, serviceClient);

            ISearchIndexClient indexClient = serviceClient.Indexes.GetClient(indexName);
        }

        private static SearchServiceClient CreateSearchServiceClient(IConfigurationRoot configuration)
        {
            string searchServiceName = configuration["SearchServiceName"];
            string adminApiKey = configuration["SearchServiceAdminApiKey"];

            SearchServiceClient serviceClient = new SearchServiceClient(searchServiceName, new SearchCredentials(adminApiKey));
            return serviceClient;
        }

        private static void DeleteIndexIfExists(string indexName, SearchServiceClient serviceClient)
        {
            if (serviceClient.Indexes.Exists(indexName))
            {
                serviceClient.Indexes.Delete(indexName);
            }
        }
        private static void CreateIndex(string indexName, SearchServiceClient serviceClient)
        {
            var definition = new Microsoft.Azure.Search.Models.Index()
            {
                Name = indexName,
                Fields = FieldBuilder.BuildForType<AesKey>()
            };
            
            serviceClient.Indexes.Create(definition);
        }
    }

    public class AesKey 
    {
        [System.ComponentModel.DataAnnotations.Key]
        [IsFilterable]
        public string keyId { get; set; }

        [IsSearchable, IsSortable]
        public string key { get; set; }

        [IsSearchable, IsFilterable, IsSortable]
        public string readHost  { get; set; }

        [IsSearchable, IsFilterable, IsSortable]
        public string writeHost  { get; set; }

        [IsSearchable, IsFilterable,IsSortable]
        public string readRegion  { get; set; }

        [IsSearchable, IsFilterable, IsSortable]
        public string writeRegion  { get; set; }

        [IsSearchable, IsFilterable, IsSortable]
        public string timeStamp { get; set; }
    }
}
