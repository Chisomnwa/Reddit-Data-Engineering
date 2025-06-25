# Database for raw data
resource "aws_glue_catalog_database" "reddit_raw_database" {
  name        = var.raw_database_name
  description = "Database for raw Reddit data"
}

# Database for transformed data  
resource "aws_glue_catalog_database" "reddit_transformed_database" {
  name        = var.transformed_database_name
  description = "Database for transformed Reddit data"
}

# Crawler for RAW data (runs first)
resource "aws_glue_crawler" "reddit_raw_crawler" {
  name          = var.reddit_raw_crawler_name
  database_name = aws_glue_catalog_database.reddit_raw_database.name
  role          = var.glue_role_arn
  description   = "Crawler for raw Reddit data"

  s3_target {
    path = "s3://${var.data_bucket_name}/raw/"
  }

  table_prefix = var.raw_table_prefix
  
  schema_change_policy {
    delete_behavior = "LOG"
    update_behavior = "UPDATE_IN_DATABASE"
  }

  configuration = jsonencode({
    Version = 1.0
    Grouping = {
      TableGroupingPolicy = "CombineCompatibleSchemas"
    }
  })
}

# Crawler for TRANSFORMED data (runs after Glue job)
resource "aws_glue_crawler" "reddit_transformed_crawler" {
  name          = var.reddit_transformed_crawler_name
  database_name = aws_glue_catalog_database.reddit_transformed_database.name
  role          = var.glue_role_arn
  description   = "Crawler for transformed Reddit data"

  s3_target {
    path = "s3://${var.data_bucket_name}/transformed/"
  }

  table_prefix = var.transformed_table_prefix
  
  schema_change_policy {
    delete_behavior = "LOG"
    update_behavior = "UPDATE_IN_DATABASE"
  }

  configuration = jsonencode({
    Version = 1.0
    Grouping = {
      TableGroupingPolicy = "CombineCompatibleSchemas"
    }
  })
}

# Glue Job that reads from cataloged raw data
resource "aws_glue_job" "reddit_glue_job" {
  name     = "reddit-glue-job"
  role_arn = var.glue_role_arn

  command {
    name            = "glueetl"
    script_location = "s3://${var.code_bucket_name}/scripts/pyspark_script.py"
    python_version  = "3"
  }

  default_arguments = {
    "--job-language"     = "python"
    "--TempDir"         = "s3://${var.data_bucket_name}/temp/"
    "--raw_database"    = aws_glue_catalog_database.reddit_raw_database.name
    "--output_path"     = "s3://${var.data_bucket_name}/transformed/"
    "--enable-continuous-cloudwatch-log" = "true"
  }

  glue_version      = "4.0"
  number_of_workers = 2
  worker_type       = "G.1X"
}

# Triggers for orchestration
resource "aws_glue_trigger" "raw_crawler_trigger" {
  name = var.raw_crawler_trigger_name
  type = "ON_DEMAND"

  actions {
    crawler_name = aws_glue_crawler.reddit_raw_crawler.name
  }
}

resource "aws_glue_trigger" "transformed_crawler_trigger" {
  name = var.transformed_crawler_trigger_name
  type = "ON_DEMAND"

  actions {
    crawler_name = aws_glue_crawler.reddit_transformed_crawler.name
  }
}