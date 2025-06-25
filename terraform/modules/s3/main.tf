# This Terraform module creates an S3 bucket with versioning enabled.
resource "aws_s3_bucket" "bucket" {
  bucket = var.bucket_name
  force_destroy = true

  tags = {
    Name        = var.bucket_tag_name
    Environment = "Dev"
    owner       = "Chisom"
    team        = "Data Engineers"
    managed_by  = "Team Leaders"
  }
}

resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

# This resource conditionally creates the Athena results folder based on the variable.
# If `create_athena_results_folder` is true, the folder will be created;
# if false, it will not create the folder. It is called ternary conditional expression.
# If we don't add this part, the folder will be created in all the s3 buckets
# because it is unconditionally defined in this shared S3 module.
resource "aws_s3_object" "athena_results_folder" {
  count  = var.create_athena_results_folder ? 1 : 0 
  bucket = aws_s3_bucket.bucket.id
  key    = "athena_query_results/"
  acl    = "private"
}

# This resource allows Redshift to access the S3 bucket.
# The bucket created does not allow public access, so we need to explicitly allow Redshift access
# using the IAM role ARN provided in the variable `redshift_role_arn`.
# If the ARN is not provided, this resource will not be created.
# This is useful when you have multiple S3 buckets and only some of them need to allow
# Redshift access, so you can pass the ARN only for those buckets that need it.
resource "aws_s3_bucket_policy" "allow_redshift" {
  count  = var.redshift_role_arn != "" ? 1 : 0
  bucket = aws_s3_bucket.bucket.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "AllowRedshiftAccess",
        Effect = "Allow",
        Principal = {
          AWS = var.redshift_role_arn
        },
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ],
        Resource = [
          "arn:aws:s3:::${aws_s3_bucket.bucket.bucket}",
          "arn:aws:s3:::${aws_s3_bucket.bucket.bucket}/*"
        ]
      }
    ]
  })
}
