# Required variables (you already have these)
variable "data_bucket_name" {
  description = "Name of the S3 bucket where data is stored"
  type        = string
}

variable "code_bucket_name" {
  description = "Name of the S3 bucket where PySpark scripts are stored"
  type        = string
}

variable "glue_role_arn" {
  description = "ARN of the IAM role for Glue"
  type        = string
}

# Optional variables for better flexibility
variable "raw_database_name" {
  description = "Name of the Glue database for raw data"
  type        = string
  default     = "reddit_raw_database"
}

variable "transformed_database_name" {
  description = "Name of the Glue database for transformed data"
  type        = string
  default     = "reddit_transformed_database"
}

variable "glue_job_name" {
  description = "Name of the Glue ETL job"
  type        = string
  default     = "reddit-glue-job"
}

variable "raw_table_prefix" {
  description = "Prefix for raw data tables"
  type        = string
  default     = "reddit_"
}

variable "transformed_table_prefix" {
  description = "Prefix for transformed data tables"
  type        = string
  default     = "reddit_"
}

variable "reddit_raw_crawler_name" {
  description = "Name of the Glue crawler for raw Reddit data"
  type        = string
  default     = "reddit_raw_crawler"
}

variable "reddit_transformed_crawler_name" {
  description = "Name of the Glue crawler for transformed Reddit data"
  type        = string
  default     = "reddit_transformed_crawler"
}

variable "raw_crawler_trigger_name" {
  description = "Name of the Glue trigger for raw Reddit data"
  type        = string
  default     = "reddit_raw_trigger"
}

variable "transformed_crawler_trigger_name" {
  description = "Name of the Glue trigger for transformed Reddit data"
  type        = string
  default     = "reddit_transformed_trigger"  
}