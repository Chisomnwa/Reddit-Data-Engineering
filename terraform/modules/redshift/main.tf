resource "aws_redshift_cluster" "reddit_pipeline_cluster" {
  cluster_identifier        = var.cluster_identifier
  database_name             = var.database_name
  master_username           = var.username
  master_password           = var.password
  node_type                 = "ra3.xlplus" # "dc2.large" has been deprecated in South Africa Region
  cluster_type              = "multi"
  number_of_nodes           = 2
  cluster_subnet_group_name = var.redshift_subnet_group
  iam_roles                 = [var.redshift_role_arn]
  skip_final_snapshot       = true
  publicly_accessible = true  # ← THIS LINE IS ESSENTIAL
  
  # This tells Terraform to ignore changes to these attributes
  # so that it doesn't try to recreate the cluster if these attributes change.
  lifecycle {
    ignore_changes = [ 
      availability_zone_relocation_enabled,
      encrypted,
      cluster_type
    ]
  }
}

#######################################################
/*
We do not plan to load data directly into the Redshift data warehouse.
Instead, we’ll use Redshift Spectrum (via an external schema) to access tables defined in the AWS Glue Data Catalog.

Although the Glue tables appear under the External Databases section in Redshift Query Editor v2, 
they cannot be queried directly unless you're using Redshift Serverless.

To enable querying from a provisioned Redshift cluster, an external schema must be created within a native Redshift database. 
This external schema maps to the Glue Data Catalog database and its tables, 
enabling Redshift to query data stored in Amazon S3 through Spectrum.
*/

/*
To create an external schema in Amazon Redshift (such as for Redshift Spectrum), you must use a native Redshift database user—not an IAM user.
A native Redshift DB user includes:
The master username that is generated when the Redshift cluster is created (in our case, stored in SSM Parameter Store as redshift_username).
You have two options:

Use the master user directly:
*/
# resource "aws_redshiftdata_statement" "create_external_schema" {
#   cluster_identifier = "reddit-cluster"
#   database           = "reddit_database"
#   db_user            = var.username  # Use your master user directly
#   sql = <<EOT
#     CREATE EXTERNAL SCHEMA IF NOT EXISTS spectrum_schema
#     FROM DATA CATALOG
#     DATABASE 'reddit_transformed_database'
#     IAM_ROLE 'arn:aws:iam::590183895800:role/redshift_service_role'
#     REGION 'af-south-1';

#     GRANT USAGE ON SCHEMA spectrum_schema TO PUBLIC;
#     GRANT SELECT ON ALL TABLES IN SCHEMA spectrum_schema TO PUBLIC;
#   EOT
# }

/*
OR 👇
Use the master user to create a new DB user (e.g., myadmin)
Grant the new user the appropriate permissions (e.g., GRANT CREATE ON DATABASE ...)
Then, use that user to create the external schema

Both approaches are valid, depending on your security or access control needs.
If you choose the first approach, comment out the second approach below.
*/

resource "aws_redshiftdata_statement" "create_myadmin_user" {
  cluster_identifier = "reddit-cluster"
  database           = "reddit_database"
  db_user            = var.username# This IAM user must have permissions to create users
  sql                = "CREATE USER myadmin PASSWORD 'StrongPassword123!';"
}

resource "aws_redshiftdata_statement" "grant_myadmin_perms" {
  depends_on = [aws_redshiftdata_statement.create_myadmin_user]
  cluster_identifier = "reddit-cluster"
  database           = "reddit_database"
  db_user            = var.username
  sql                = "GRANT CREATE ON DATABASE reddit_database TO myadmin;"
}

# Uncomment if you want to create the external schema using the new user (myadmin)
# resource "aws_redshiftdata_statement" "create_external_schema" {
#   depends_on = [aws_redshiftdata_statement.grant_myadmin_perms]
#   cluster_identifier = "reddit-cluster"
#   database           = "reddit_database"
#   db_user            = var.username
#   sql = <<EOT
#     CREATE EXTERNAL SCHEMA IF NOT EXISTS spectrum_schema
#     FROM DATA CATALOG
#     DATABASE 'reddit_transformed_database'
#     IAM_ROLE 'arn:aws:iam::590183895800:role/redshift_service_role'
#     REGION 'af-south-1';

#     GRANT USAGE ON SCHEMA spectrum_schema TO PUBLIC;
#     GRANT SELECT ON ALL TABLES IN SCHEMA spectrum_schema TO PUBLIC;
#   EOT
# }

/*
We can also create an external schema using the  RedshiftDataOperator in Airflow,
which allows us to run SQL commands directly against the Redshift cluster.
This is useful for creating the external schema after the Glue crawler has run and created the necessary tables
in the Glue Data Catalog.

And if you want to create the external schema in Airflow, then you just need to create a dedicated db user (e.g., myadmin)
with the necessary permissions to create the external schema. Just as shown above.

You will only be creating the external schema via airflow.

I have shown you how you can do it in the airflow/dags/reddit_dag.py file.
*/
