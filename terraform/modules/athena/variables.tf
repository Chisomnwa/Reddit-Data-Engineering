variable "data_bucket_name" {
  type        = string
  description = "The S3 bucket for storing Reddit data"
}

# variable "script_bucket_name" {
#   type        = string
#   description = "The S3 buck`et for storing PySpark scripts"
# }

variable "workgroup_name" {
  description = "Name of the Athena workgroup"
  type        = string
  default     = "reddit-data-workgroup"
}

variable "query_result_bucket" {
  description = "S3 bucket name for query results"
  type        = string
}

variable "query_result_prefix" {
  description = "Prefix (folder) inside the bucket to store results"
  type        = string
  default     = "query-results"
}

variable "database_name" {
  description = "Name of the Glue database Athena should query from"
  type        = string
}

variable "table_prefix" {
  description = "Prefix of the transformed data tables in Glue catalog"
  type        = string
  default     = "reddit_"
}

variable "transformed_data_prefix" {
  description = "Prefix/folder under the data bucket where transformed data is stored"
  type        = string
  default     = "transformed/"
}


