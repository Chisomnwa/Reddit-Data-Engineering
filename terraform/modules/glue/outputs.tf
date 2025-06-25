output "transformed_database_name" {
  value = aws_glue_catalog_database.reddit_transformed_database.name
}

output "transformed_table_prefix" {
  value = var.transformed_table_prefix
}
