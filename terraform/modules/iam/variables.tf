variable "data_bucket_name" {
  type        = string
  description = "The S3 bucket for storing Reddit data"
}

variable "script_bucket_name" {
  type        = string
  description = "The S3 bucket for storing PySpark scripts"
}

variable "aws_region" {
  type        = string
  description = "The AWS region"
}

variable "aws_account_id" {
  type        = string
  description = "The AWS account ID"
}
