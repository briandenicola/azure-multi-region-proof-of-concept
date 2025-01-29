resource "azurerm_redis_enterprise_database" "cqrs" {
  depends_on = [
    module.global_resources, module.regional_resources
  ]

  name              = "default"
  cluster_id        = module.regional_resources[element(var.locations, 0)].AZURE_REDIS_CLUSTER_DATABASE_ID
  client_protocol   = "Encrypted"
  clustering_policy = "EnterpriseCluster"
  eviction_policy   = "NoEviction"
  port              = 10000

  module {
    name = "RediSearch"
  }

  linked_database_id             = [ for i in toset(var.locations) : "${module.regional_resources[i].AZURE_REDIS_CLUSTER_DATABASE_ID}/databases/${local.redis_database_name}" ]
  linked_database_group_nickname = "CQRSRedisDatabase"
}