variable "redshift_role_arn" {
  type        = string
  description = "The ARN of the Redshift IAM role that needs Lake Formation permissions"
}

variable "database_name" {
  type        = string
  description = "The name of the Glue database for Lake Formation permissions"
  default     = "reddit_transformed_database"
}