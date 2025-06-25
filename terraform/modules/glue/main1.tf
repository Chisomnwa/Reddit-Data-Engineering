# resource "aws_glue_catalog_database" "reddit_database" {
#   name         = "reddit_database"
#   location_uri = "s3://${var.data_bucket_name}/"
# }

# resource "aws_glue_crawler" "reddit_crawler" {
#   name          = "reddit_database_crawler"
#   database_name = aws_glue_catalog_database.reddit_database.name
#   role          = var.glue_role_arn

#   s3_target {
#     path = "s3://${var.data_bucket_name}/"
#   }

#   schema_change_policy {
#     delete_behavior = "LOG"
#   }

#   configuration = <<EOF
#   {
#     "Version": 1.0,
#     "Grouping": {
#       "TableGroupingPolicy": "CombineCompatibleSchemas"
#     }
#   }
# EOF
# }

# resource "aws_glue_trigger" "org_report_trigger" {
#   name = "org-report-trigger"
#   type = "ON_DEMAND"

#   actions {
#     crawler_name = aws_glue_crawler.reddit_crawler.name
#   }
# }

# resource "aws_glue_job" "reddit_glue_job" {
#   name     = "reddit-glue-job"
#   role_arn = var.glue_role_arn

#   command {
#     name            = "glueetl"
#     script_location = "s3://${var.code_bucket_name}/scripts/pyspark_script.py"
#     python_version  = "3"
#   }

#   default_arguments = {
#     "--job-language" = "python"
#     "--TempDir"      = "s3://${var.data_bucket_name}/temp/"
#     "--input_path"   = "s3://${var.data_bucket_name}/raw/"
#     "--output_path"  = "s3://${var.data_bucket_name}/transformed/"
#   }

#   glue_version = "4.0"
#   number_of_workers = 2
#   worker_type       = "G.1X"
# }
