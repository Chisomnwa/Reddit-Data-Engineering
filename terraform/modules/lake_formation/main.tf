# This Terraform module grants permissions to a Redshift role for accessing a Lake Formation database and its tables.
data "aws_caller_identity" "current" {}

# 1. First grant database permissions
resource "aws_lakeformation_permissions" "grant_select_to_redshift" {
  principal   = var.redshift_role_arn
  permissions = ["DESCRIBE"] # Start with DESCRIBE only

  database {
    name       = var.database_name
    catalog_id = data.aws_caller_identity.current.account_id
  }
}

# 2. Then grant table permissions (with explicit depends_on)
resource "aws_lakeformation_permissions" "grant_select_to_redshift_tables" {
  principal   = var.redshift_role_arn
  permissions = ["SELECT"]

  table {
    database_name = var.database_name
    name          = "reddit_transformed"
    catalog_id    = data.aws_caller_identity.current.account_id
  }

  depends_on = [
    aws_lakeformation_permissions.grant_select_to_redshift,
    # Add any other dependencies if needed
  ]
}