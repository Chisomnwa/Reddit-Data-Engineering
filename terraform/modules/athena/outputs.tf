output "athena_output_location" {
  description = "S3 location where Athena will store query results"
  value       = "s3://${var.query_result_bucket}/${var.query_result_prefix}/"
}

output "athena_workgroup_name" {
  description = "Name of the created Athena workgroup"
  value       = aws_athena_workgroup.this.name
}
