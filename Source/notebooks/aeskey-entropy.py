# Databricks notebook source
import pyspark
from pyspark.sql import SparkSession
from pyspark.sql.functions import col, lit

df = (spark
  .read
  .parquet("/mnt/entropy")
  .withColumn("body",col("body").cast("String"))
)     

# COMMAND ----------
import base64 
import json

w = (df.select("body")
     .rdd
     .map(lambda row: json.loads(row.body))
     .flatMap(lambda obj: base64.b64decode(obj['key']))
     .map(lambda b: {"ByteId":str(b), "Value": 1})
     .toDF()
     .groupBy("ByteId")
     .sum("Value")
    )

display(w)


# COMMAND ----------


