variable "redshift_subnet_group" {
  description = "Subnet group for the Redshift cluster"
  type        = string
}

variable "redshift_role_arn" {
  description = "IAM role ARN for the Redshift cluster"
  type        = string
}

variable "username" {
  description = "Master username for the Redshift cluster"
  type        = string
}

variable "password" {
  description = "Master password for the Redshift cluster"
  type        = string
}

variable "database_name" {
  description = "Database name for the Redshift cluster"
  type        = string
}

variable "cluster_identifier" {
  description = "Identifier for the Redshift cluster"
  type        = string
}

variable aws_region {
  description = "AWS region for the Redshift cluster"
  type        = string
}

# variable "admin_username" {
#   type        = string
#   description = "Redshift admin username"
#   default     = "admin_chisom"  # Match your actual admin username
# }