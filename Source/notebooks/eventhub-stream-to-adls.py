# Databricks notebook source
try:
  dbutils.fs.unmount('/mnt/entropy')
except:
  print("/mnt/entropy not mounted")
 
configs = {
  "fs.azure.account.auth.type": "OAuth", 
  "fs.azure.account.oauth.provider.type": "org.apache.hadoop.fs.azurebfs.oauth2.ClientCredsTokenProvider",
  "fs.azure.account.oauth2.client.id": dbutils.secrets.get(scope = "entropy-demo", key = "client-id"),
  "fs.azure.account.oauth2.client.secret":  dbutils.secrets.get(scope = "entropy-demo", key = "client-secret"),
  "fs.azure.account.oauth2.client.endpoint": dbutils.secrets.get(scope = "entropy-demo", key = "client-tenant")
}

dbutils.fs.mount(
  source = "abfss://parquet@[StorageAccountName].dfs.core.windows.net/",
  mount_point = "/mnt/entropy",
  extra_configs = configs)

# COMMAND ----------

connectionString = dbutils.secrets.get(scope = "entropy-demo", key = "eventhub-connnection-string")

ehConf = {
  'eventhubs.connectionString' : sc._jvm.org.apache.spark.eventhubs.EventHubsUtils.encrypt(connectionString),
  'eventhubs.consumerGroup': "databricks"
}

df = (spark 
  .readStream 
  .format("eventhubs") 
  .options(**ehConf) 
  .load())

# COMMAND ----------

df \
 .writeStream \
 .format("parquet") \
 .outputMode("append") \
 .option("checkpointLocation", "/mnt/entropy/_checkpoints/write") \
 .option("path", "/mnt/entropy") \
 .start()
