# Variables for S3 bucket module
variable "bucket_name" {
  description = "Name of the S3 bucket"
  type        = string
}

variable "bucket_tag_name" {
  description = "Name tag for the bucket"
  type        = string
}

variable "create_athena_results_folder" {
  description = "Whether to create the athena_query_results/ folder in this bucket"
  type        = bool
  default     = false
}

# This is necessary because the bucket blocked public access
# and we need to allow Redshift to access the bucket.
variable "redshift_role_arn" {
  description = "IAM Role ARN for Redshift access to the bucket"
  type        = string
  default     = ""  # Leave empty unless explicitly passed
}
