output "redshift_s3_role_arn" {
    value = aws_iam_role.redshift_role.arn
}

output "redshift_s3_custom_policy_arn" {
    value = aws_iam_policy.redshift_s3_custom_policy.arn

}

output "glue_s3_role_arn" {
    value = aws_iam_role.glue_role.arn
}

output "glue_s3_policy_arn" {
    value = aws_iam_policy.glue_s3_custom_policy.arn
}

