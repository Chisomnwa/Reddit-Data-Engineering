module "vpc" {
  source = "./modules/vpc"
}

module "my_s3_data_bucket" {
  source                       = "./modules/s3"
  bucket_name                  = "reddit-data-bucket-2025"
  bucket_tag_name              = "Reddit ETL"
  create_athena_results_folder = true # Explictly enable creation of the Athena results folder
}

module "my_s3_script_bucket" {
  source                       = "./modules/s3"
  bucket_name                  = "reddit-pyspark-script-bucket-2025"
  bucket_tag_name              = "Reddit ETL PySpark Script"
  create_athena_results_folder = false                        # Explictly disable creation of the Athena results folder
  redshift_role_arn            = module.iam.redshift_role_arn # Pass the Redshift role ARN to allow access
}

module "iam" {
  source             = "./modules/iam"
  data_bucket_name   = module.my_s3_data_bucket.bucket_name
  script_bucket_name = module.my_s3_script_bucket.bucket_name
  aws_region         = "af-south-1"   # Replace if using a different region
  aws_account_id     = "590183895800" # Your actual AWS Account ID
}

output "glue_s3_role_arn" {
  value = module.iam.glue_role_arn
}

output "redshift_s3_glue_lf_role_arn" {
  value = module.iam.redshift_role_arn
}

module "glue" {
  source           = "./modules/glue"
  data_bucket_name = module.my_s3_data_bucket.bucket_name
  code_bucket_name = module.my_s3_script_bucket.bucket_name
  glue_role_arn    = module.iam.glue_role_arn # Name of the Glue database for raw data
}

module "athena" {
  source = "./modules/athena"

  data_bucket_name = module.my_s3_data_bucket.bucket_name # from your s3 module
  # script_bucket_name    = module.s3.script_bucket_name        # if needed
  workgroup_name          = "reddit_athena_workgroup"
  query_result_bucket     = module.my_s3_data_bucket.bucket_name # where Athena will store query results
  query_result_prefix     = "reddit_query"                       # a folder/prefix inside the data bucket
  database_name           = module.glue.transformed_database_name
  table_prefix            = module.glue.transformed_table_prefix # optional
  transformed_data_prefix = "transformed/"                       # or expose from glue module
}

data "aws_ssm_parameter" "password" {
  name = "redshift_password"
}

data "aws_ssm_parameter" "username" {
  name = "redshift_username"
}

module "ssm" {
  source = "./modules/ssm"
}

module "redshift" {
  source                = "./modules/redshift"
  redshift_subnet_group = module.vpc.subnet_group_id
  redshift_role_arn     = module.iam.redshift_role_arn # Pointing to the output of the iam_roles
  username              = data.aws_ssm_parameter.username.value
  password              = data.aws_ssm_parameter.password.value
  database_name         = "reddit_database"
  cluster_identifier    = "reddit-cluster" # It must contain only lowercase alphanumeric characters (a-z, 0-9) and hyphens (-).
  aws_region            = "af-south-1"     # ADD THIS LINE - matching the region you're using
}
