# resource "aws_glue_catalog_database" "reddit_database" {
#   name         = "reddit_database"
#   description  = "Database for transformed Reddit data"
#   # Remove location_uri - let Glue manage this automatically
# }

# # Crawler should point to TRANSFORMED data, not raw data
# resource "aws_glue_crawler" "reddit_crawler" {
#   name          = "reddit_transformed_crawler"
#   database_name = aws_glue_catalog_database.reddit_database.name
#   role          = var.glue_role_arn
#   description   = "Crawler for transformed Reddit data"

#   # Point to transformed folder specifically
#   s3_target {
#     path = "s3://${var.data_bucket_name}/transformed/"
#   }

#   schema_change_policy {
#     delete_behavior = "LOG"
#     update_behavior = "UPDATE_IN_DATABASE"
#   }

#   # Add table prefix for better organization
#   table_prefix = "reddit_"

#   configuration = jsonencode({
#     Version = 1.0
#     Grouping = {
#       TableGroupingPolicy = "CombineCompatibleSchemas"
#     }
#   })

#   # Schedule to run after Glue job completes (optional)
#   schedule = "cron(0 2 * * ? *)"  # Daily at 2 AM
# }

# resource "aws_glue_trigger" "reddit_crawler_trigger" {
#   name = "reddit-crawler-trigger"
#   type = "ON_DEMAND"  # Change to SCHEDULED if you want automatic runs

#   actions {
#     crawler_name = aws_glue_crawler.reddit_crawler.name
#   }
# }

# resource "aws_glue_job" "reddit_glue_job" {
#   name     = "reddit-glue-job"
#   role_arn = var.glue_role_arn
#   description = "ETL job to transform Reddit data"

#   command {
#     name            = "glueetl"
#     script_location = "s3://${var.code_bucket_name}/scripts/pyspark_script.py"
#     python_version  = "3"
#   }

#   default_arguments = {
#     "--job-language"           = "python"
#     "--TempDir"               = "s3://${var.data_bucket_name}/temp/"
#     "--input_path"            = "s3://${var.data_bucket_name}/raw/"
#     "--output_path"           = "s3://${var.data_bucket_name}/transformed/"
#     "--enable-continuous-cloudwatch-log" = "true"
#     "--enable-spark-ui"       = "true"
#     "--spark-event-logs-path" = "s3://${var.data_bucket_name}/spark-logs/"
#   }

#   glue_version      = "4.0"
#   max_retries       = 1
#   timeout           = 60
#   number_of_workers = 2
#   worker_type       = "G.1X"

#   execution_property {
#     max_concurrent_runs = 1
#   }
# }