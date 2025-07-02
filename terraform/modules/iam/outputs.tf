# Remove the duplicate - you have both redshift_s3_role_arn and redshift_role_arn
output "redshift_role_arn" {
  description = "The ARN of the Redshift IAM role"
  value       = aws_iam_role.redshift_role.arn
}

output "redshift_policy_arn" {
  description = "The ARN of the Redshift IAM policy"
  value       = aws_iam_policy.redshift_s3_glue_lf_policy.arn
}

output "glue_role_arn" {
  description = "The ARN of the Glue IAM role"
  value       = aws_iam_role.glue_role.arn
}

output "glue_policy_arn" {
  description = "The ARN of the Glue IAM policy"
  value       = aws_iam_policy.glue_s3_custom_policy.arn
}