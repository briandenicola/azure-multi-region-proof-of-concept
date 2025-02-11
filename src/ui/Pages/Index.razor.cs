using System.Threading.Tasks;
using System.Collections.Generic;
using Microsoft.AspNetCore.Components;
using cqrs.ui.models;

namespace cqrs.ui.pages {

    public class IndexComponent : ComponentBase
    {
        protected int numKeys = 50;
        protected List<AesKey>? keys;

        [Inject]
        protected KeyService? req { get; set; }

        protected async Task HandleHttpRequest()
        {
            if( req == null ) return;
            keys = await req.SendPostRequest(numKeys);
        }

        protected Task HandleSaveConfig() {
            return Task.FromResult(true);
        }
    }
}