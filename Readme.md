# Introduction
A very simple setup for Command Query Responsibility Separation (CQRS) in Azure. 


# To Do List 
- [x] Infrastructure Setup
- [x] Test Flexvol with local.settings.json for Functions in container
- [x] Python Script to create events published to Event Hub
- [x] Azure Function to process event, storing in Cosmos and Redis Cache
- [x] Go Write API to generate events to Event Hub 
- [x] Go Read API to read from Redis 
- [ ] Go Read API to read from Cosmos db using SQL API
- [ ] Deployment artifacts to Kubernetes
- [ ] Azure DevOps Multistage Pipeline for build/deploy

# Issues
- [x] Docker build on Azure Functions has warnings. func kubernetes deploy does not
    * docker build -t bjd145/eventprocessor:1.1 . 
        * /root/.nuget/packages/microsoft.azure.webjobs.script.extensionsmetadatagenerator/1.1.2/build/Microsoft.Azure.WebJobs.Script.ExtensionsMetadataGenerator.targets(52,5): warning :     Could not evaluate 'Cosmos.CRTCompat.dll' for extension metadata. Exception message: Bad IL format. [/src/dotnet-function-app/eventing.csproj]
        * Downgrading to Microsoft.NET.Sdk.Functions Version "1.0.24" resolved the issue