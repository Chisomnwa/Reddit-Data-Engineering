# This script is an AWS Glue job that reads a CSV file from S3, 
# transforms it by concatenating the 'edited', 'spoiler', and 'stickied' columns, 
# and writes the result back to S3.

import sys
import datetime
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from pyspark.sql.types import StructType, StructField, StringType
from pyspark.sql.functions import concat_ws, col
from awsglue.dynamicframe import DynamicFrame

# Get job arguments
args = getResolvedOptions(sys.argv, ['JOB_NAME', 'input_path', 'output_path'])

# Initialize Glue and Spark contexts
sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args['JOB_NAME'], args)

# Define schema explicitly to avoid type conversion issues (especially with booleans)
schema = StructType([
    StructField("id", StringType()),
    StructField("title", StringType()),
    StructField("score", StringType()),
    StructField("num_comments", StringType()),
    StructField("author", StringType()),
    StructField("edited", StringType()),    # Avoid using BooleanType here
    StructField("spoiler", StringType()),
    StructField("stickied", StringType())
    # Add more fields here if your dataset has them
])

# Read CSV from S3 using Spark
df = spark.read.csv(
    args['input_path'],
    header=True,
    schema=schema
)

# Concatenate the 'edited', 'spoiler', and 'stickied' columns into a new column
df_combined = df.withColumn(
    "ESS_Updated",
    concat_ws("-", col("edited"), col("spoiler"), col("stickied"))
).drop("edited", "spoiler", "stickied")

# Convert DataFrame back to DynamicFrame
s3bucket_node_combined = DynamicFrame.fromDF(df_combined, glueContext, "s3bucket_node_combined")

# Create a unique, readable file name with timestamp
timestamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
output_path_with_filename = f"{args['output_path']}reddit_transformed_{timestamp}.csv"

# Write the transformed data back to S3
glueContext.write_dynamic_frame.from_options(
    frame=s3bucket_node_combined,
    connection_type="s3",
    format="csv",
    connection_options={
        "path": args['output_path'],
        "partitionKeys": []
    },
    transformation_ctx="AmazonS3_node2"
)

# Commit the job
job.commit()