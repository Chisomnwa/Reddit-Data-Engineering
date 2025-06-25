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
