# IAM Role for Glue to access S3 bucket
resource "aws_iam_role" "glue_role" {
  name = "glue_service_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Sid    = "",
        Principal = {
          Service = "glue.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    name = "reddit_pipeline_role"
  }
}

# IAM Policy with extended Glue permissions
resource "aws_iam_policy" "glue_s3_custom_policy" {
  name        = "GlueS3CustomPolicy"
  description = "Policy to allow Glue access to S3, Glue Catalog, and logging"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [

      # S3 access
      {
        Sid = "AllowListBucket",
        Effect = "Allow",
        Action = ["s3:ListBucket"],
        Resource = [
          "arn:aws:s3:::${var.data_bucket_name}",
          "arn:aws:s3:::${var.script_bucket_name}"
        ]
      },
      {
        Sid = "AllowObjectOperations",
        Effect = "Allow",
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:PutObject",
          "s3:DeleteObject"
        ],
        Resource = [
          "arn:aws:s3:::${var.data_bucket_name}/*",
          "arn:aws:s3:::${var.script_bucket_name}/*"
        ]
      },

      # Glue Catalog access (important for crawler & jobs)
      {
        Sid = "AllowGlueCatalogAccess",
        Effect = "Allow",
        Action = [
          "glue:GetDatabase",
          "glue:GetDatabases",
          "glue:CreateDatabase",
          "glue:UpdateDatabase",
          "glue:DeleteDatabase",
          "glue:GetTable",
          "glue:GetTables",
          "glue:CreateTable",
          "glue:UpdateTable",
          "glue:DeleteTable",
          "glue:GetPartition",
          "glue:GetPartitions"
        ],
        Resource = [
          "arn:aws:glue:${var.aws_region}:${var.aws_account_id}:catalog",
          "arn:aws:glue:${var.aws_region}:${var.aws_account_id}:database/reddit_raw_database",
          "arn:aws:glue:${var.aws_region}:${var.aws_account_id}:table/reddit_raw_database/*",
          "arn:aws:glue:${var.aws_region}:${var.aws_account_id}:database/reddit_transformed_database",
          "arn:aws:glue:${var.aws_region}:${var.aws_account_id}:table/reddit_transformed_database/*"
        ]
      },

      # Athena access (if querying data post-job)
      {
        Sid = "AllowAthenaQueries",
        Effect = "Allow",
        Action = [
          "athena:StartQueryExecution",
          "athena:GetQueryExecution",
          "athena:GetQueryResults",
          "athena:GetWorkGroup",
          "athena:ListWorkGroups"
        ],
        Resource = "*"
      },

      # CloudWatch Logs for Glue job logs
      {
        Sid = "AllowCloudWatchLogs",
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "*"
      }
    ]
  })
}

# Attach the policy to the Glue role
resource "aws_iam_policy_attachment" "glue_role_attachment" {
  name       = "attach_glue_s3_policy"
  roles      = [aws_iam_role.glue_role.name]
  policy_arn = aws_iam_policy.glue_s3_custom_policy.arn
}


############################################################
# IAM Role for Redshift to access S3, Glue, and Lake Formation
resource "aws_iam_role" "redshift_role" {
  name = "redshift_service_role"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "redshift.amazonaws.com"
        }
      },
    ]
  })

  tags = {
    name = "reddit_pipeline_role"
  }
}

# IAM Policy with S3, Glue, and Lake Formation permissions
resource "aws_iam_policy" "redshift_s3_glue_lf_policy" {
  name        = "RedshiftS3GlueLakeFormationPolicy"
  description = "Policy to allow Redshift access to S3, Glue Catalog, and Lake Formation"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid = "AllowListBucket",
        Effect = "Allow",
        Action = [
          "s3:ListBucket"
        ],
        Resource = "arn:aws:s3:::${var.data_bucket_name}"
      },
      {
        Sid = "AllowObjectOperations",
        Effect = "Allow",
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:PutObject",
          "s3:DeleteObject"
        ],
        Resource = "arn:aws:s3:::${var.data_bucket_name}/*"
      },
      {
        Sid = "AllowGlueCatalogAccess",
        Effect = "Allow",
        Action = [
          "glue:*"
        ],
        Resource = "*"
      },
      # Lake Formation is an AWS service that manages data access control on top of the AWS Glue Data Catalog.
      # Even if your IAM role has permission to access S3 and Glue, Lake Formation can still block access 
      # unless you explicitly grant permissions there.
      # Think of it as a security layer for querying data in S3 via Athena or Redshift Spectrum.
      # So, this is saying; this role is allowed to talk to lake formation.
      {
        Sid = "AllowLakeFormationAccess",
        Effect = "Allow",
        Action = [
          "lakeformation:GetDataAccess"
        ],
        Resource = "*"
      },
    ]
  })
}

# Attach the policy to the Redshift IAM role
resource "aws_iam_role_policy_attachment" "attach_policy_to_redshift_role" {
  role       = aws_iam_role.redshift_role.name
  policy_arn = aws_iam_policy.redshift_s3_glue_lf_policy.arn
}

##########################################################