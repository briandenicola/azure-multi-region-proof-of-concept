using System;
using System.Web;
using System.Net.Http;
using System.Text.Json;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Components;
using cqrs_ui.models;

namespace cqrs_ui.pages {
    public class DetailsComponent : ComponentBase
    {
        [Parameter]
        public string id { get; set; }
        protected string region { get; set; } = String.Empty;
        public AesKey key { get; set; }

        private Uri uri; 


        [Inject]
        protected KeyService req { get; set; }

        protected override async Task OnInitializedAsync()
        {
            key = await req.SendGetRequest(id, String.Empty);
        }

        protected async Task HandleHttpRequest()
        { 
            key = await req.SendGetRequest(id, region);
        }                    
        
    }
}