-- SQL Query for creating redshift spectrum or external schema in redshift
-- Used when we do not want to load data into redshift tables directly

CREATE EXTERNAL SCHEMA IF NOT EXISTS spectrum_schema
FROM DATA CATALOG
DATABASE 'reddit_transformed_database'
IAM_ROLE 'arn:aws:iam::590183895800:role/redshift_service_role'
REGION 'af-south-1';

GRANT USAGE ON SCHEMA spectrum_schema TO PUBLIC;
GRANT SELECT ON ALL TABLES IN SCHEMA spectrum_schema TO PUBLIC;
