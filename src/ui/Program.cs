
using System.Threading.Tasks;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.AspNetCore.Components.WebAssembly.Hosting;
using cqrs_ui.models; 

namespace cqrs_ui
{
    public class Program
    {
        public static async Task Main(string[] args)
        {
            var builder = WebAssemblyHostBuilder.CreateDefault(args);            
            builder.Services.AddSingleton<KeyService>();
            builder.RootComponents.Add<App>("app");
            //builder.Services.AddScoped(sp => new KeyService() );

            var host = builder.Build();
            var req = host.Services.GetRequiredService<KeyService>();
            await builder.Build().RunAsync();
        }
    }
}