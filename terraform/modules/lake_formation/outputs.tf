output "database_permissions_id" {
  description = "The ID of the Lake Formation database permissions"
  value       = aws_lakeformation_permissions.grant_select_to_redshift.id
}

output "table_permissions_id" {
  description = "The ID of the Lake Formation table permissions"
  value       = aws_lakeformation_permissions.grant_select_to_redshift_tables.id
}