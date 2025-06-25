resource "aws_athena_workgroup" "this" {
  name = var.workgroup_name

  configuration {
    result_configuration {
      output_location = "s3://${var.query_result_bucket}/${var.query_result_prefix}/"
    }
  }

  description    = "Athena workgroup for querying Reddit data"
  state          = "ENABLED"
  force_destroy  = true
}
