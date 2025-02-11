using System;
using System.Web;
using System.Threading.Tasks;
using System.Text.Json;
using System.Net.Http;
using System.Collections.Generic;

namespace cqrs.ui.models {
    public class KeyService {
        public string uri { get; set; } = "https://your-api-name.azure-api.net";

        public string uriPath { get; set; } = "/k/keys";

        public string apiVersion { get; set; } = "api-version=2025-01-01";
        
        public string subscriptionKey  { get; set; } = "your-subscription-key";

        public HttpClient httpClient { get; set; }

        public KeyService() {
            httpClient = new HttpClient();
        }

        public async Task<string> SendRequest(HttpMethod method, Uri fqdn)
        {
            var request = new HttpRequestMessage(method, fqdn);
            request.Headers.Add("Ocp-Apim-Subscription-Key", subscriptionKey);
            var response = await httpClient.SendAsync(request);
            if (response.IsSuccessStatusCode) { 
                return await response.Content.ReadAsStringAsync();
            }
            return String.Empty;
        }

        public async Task<List<AesKey>> SendPostRequest(int requstedKeys)
        {   
            List<AesKey> keys = new List<AesKey>();

            if( Uri.TryCreate( new Uri(uri), $"{uriPath}/{requstedKeys}?{apiVersion}", out Uri? fqdn) ) {
                keys = JsonSerializer.Deserialize<List<AesKey>>(await SendRequest(HttpMethod.Post, fqdn)) ?? new List<AesKey>();
            }
            return keys;
        }

        public async Task<AesKey> SendGetRequest(string id, string region) 
        {
            AesKey key = new AesKey();

            if( Uri.TryCreate( new Uri(uri), $"{uriPath}/{id}?{apiVersion}", out Uri? fqdn) )
            {
                if( region != String.Empty ) 
                {
                    var uriBuilder = new UriBuilder(fqdn);
                    var query = HttpUtility.ParseQueryString(uriBuilder.Query);
                    query["forcedRegion"] = region;
                    uriBuilder.Query = query.ToString();
                    fqdn = uriBuilder.Uri;         
                }  
                
                key = JsonSerializer.Deserialize<AesKey>(await SendRequest(HttpMethod.Get, fqdn)) ?? new AesKey();
            }

            return key;
        }
    }
}