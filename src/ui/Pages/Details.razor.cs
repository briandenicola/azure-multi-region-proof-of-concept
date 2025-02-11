using System;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Components;
using cqrs.ui.models;

namespace cqrs.ui.pages {
    public class DetailsComponent : ComponentBase
    {
        [Parameter]
        public string id        { get; set; } = String.Empty;
        protected string region { get; set; } = String.Empty;
        public AesKey key       { get; set; } = new AesKey();

        [Inject]
        protected KeyService? req { get; set; }

        protected override async Task OnInitializedAsync()
        {
            if( req == null ) return;
            key = await req.SendGetRequest(id, String.Empty);
        }

        protected async Task HandleHttpRequest()
        { 
            if( req == null ) return;
            key = await req.SendGetRequest(id, region);
        }                    
        
    }
}