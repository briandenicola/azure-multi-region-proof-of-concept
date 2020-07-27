# Databricks notebook source
import json
import base64
from pyspark.sql.types import *
from pyspark.sql.functions import from_json,col, explode, current_timestamp

# COMMAND ----------
connectionString = dbutils.secrets.get(scope = "entropy-demo", key = "eventhub-connnection-string")

configs = {
  "fs.azure.account.auth.type": "OAuth", 
  "fs.azure.account.oauth.provider.type": "org.apache.hadoop.fs.azurebfs.oauth2.ClientCredsTokenProvider",
  "fs.azure.account.oauth2.client.id": dbutils.secrets.get(scope = "entropy-demo", key = "client-id"),
  "fs.azure.account.oauth2.client.secret":  dbutils.secrets.get(scope = "entropy-demo", key = "client-secret"),
  "fs.azure.account.oauth2.client.endpoint": dbutils.secrets.get(scope = "entropy-demo", key = "client-tenant")
}

# COMMAND ----------
try:
  dbutils.fs.unmount('/mnt/entropy')
except:
  print("/mnt/entropy not mounted")
  
dbutils.fs.mount(
  source = "abfss://parquet@[storageAccount].dfs.core.windows.net/",
  mount_point = "/mnt/entropy",
  extra_configs = configs)

# COMMAND ----------
#spark.sql("DROP TABLE entropy")
spark.sql("CREATE TABLE entropy (ByteID STRING, Values LONG) USING DELTA LOCATION '/mnt/entropy/delta/'")

# COMMAND ----------
def decodeB64String(encodedStr):
  return([str(b) for b in base64.b64decode(encodedStr)])

def emitValue():
  return 1

decodeB64String = udf(decodeB64String, ArrayType(StringType()))
emitValue = udf(emitValue, IntegerType())

schema = StructType([
    StructField("keyId", StringType(), True),
    StructField("key", StringType(), True)
])

ehConf = {
  'eventhubs.connectionString' : connectionString,
  'eventhubs.consumerGroup': "databricks"
}

df = (spark 
  .readStream 
  .format("eventhubs") 
  .options(**ehConf) 
  .load())

jsonDF = (df
  .withColumn("body",col("body").cast("String"))
  .withColumn("jsonData", from_json(col('body'),schema))
  .select('jsonData.*'))

tokenizeDF = (jsonDF
  .withColumn("ByteID",explode(decodeB64String(jsonDF.key)))
  .select('ByteID')
  .withColumn("values",emitValue())
  .groupBy('ByteID')
  .sum('values')
  .select('ByteID',col("sum(Values)").alias("Values")))

# COMMAND ----------
(tokenizeDF.writeStream
  .format("delta")
  .outputMode("complete")
  .option("checkpointLocation", "/mnt/entropy/delta/events/_checkpoints/etl-from-stream")
  .start("/mnt/entropy/delta/")
)
