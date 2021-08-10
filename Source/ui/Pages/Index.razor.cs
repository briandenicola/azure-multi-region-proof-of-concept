using System;
using System.Threading.Tasks;
using System.Net.Http;
using System.Text.Json;
using System.Collections.Generic;
using Microsoft.AspNetCore.Components;
using System.ComponentModel.DataAnnotations;
using cqrs_ui.models;

namespace cqrs_ui.pages {

    public class IndexComponent : ComponentBase
    {
        protected int numKeys = 50;
        protected List<AesKey> keys;

        [Inject]
        protected KeyService req { get; set; }

        protected async Task HandleHttpRequest()
        {
            keys = await req.SendPostRequest(numKeys);
        }

        protected Task HandleSaveConfig() {
            return Task.FromResult(true);
        }
    }
}