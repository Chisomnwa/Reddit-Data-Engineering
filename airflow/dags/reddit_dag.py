import os
import sys
from datetime import datetime, timedelta

# Airflow imports
from airflow import DAG
from airflow.providers.standard.operators.python import PythonOperator
from airflow.providers.amazon.aws.operators.redshift_data import RedshiftDataOperator
# from airflow.providers.amazon.aws.transfers.s3_to_redshift import S3ToRedshiftOperator
from airflow.providers.amazon.aws.sensors.glue import GlueJobSensor
from airflow.providers.amazon.aws.sensors.glue_crawler import GlueCrawlerSensor

# Custom module imports
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from pipelines.reddit_pipeline import reddit_pipeline
from pipelines.aws_s3_pipeline import upload_raw_data_pipeline, upload_glue_script_pipeline
from utils.constants import AWS_DATA_BUCKET_NAME, REDSHIFT_ROLE_ARN, AWS_REGION, REDSHIFT_DB_USER
from pipelines.glue_pipeline import trigger_glue_job, trigger_glue_crawler
from pipelines.redshift_pipeline import validate_spectrum_schema, load_sql_from_volume

# Load SQL scripts from the mounted Docker volume directory
placeholders = {
    "REDSHIFT_ROLE_ARN": REDSHIFT_ROLE_ARN,
    "AWS_REGION": AWS_REGION
}

sql_statements = load_sql_from_volume("/opt/airflow/sql", placeholders)

# Load the script for creating our Spectrum schema
create_schema_sql = sql_statements["create_spectrum_schema.sql"]

# If you want to create a table instead of an external schema, you can load the create table SQL script
# create_table_sql = sql_statements["create_table.sql"]


# Define default arguments for the DAG
default_args = {
    'owner': 'Chisom Nnamani',
    # 'start_date': datetime(2025, 6, 22),
    'start_date': datetime.today() - timedelta(days=1), # Start from yesterday to avoid issues with the first automatic run
    'retries': 2,
    'retry_delay': timedelta(seconds=5),
    'execution_timeout': timedelta(minutes=10),
}

# Generate a unique file postfix based on the current date
file_postfix = datetime.now().strftime('%Y%m%d')

# Define the DAG
dag = DAG(
    dag_id='etl_reddit_pipeline',
    default_args=default_args,
    schedule='@daily',
    catchup=False,
    tags=['reddit', 'etl', 'pipeline']
)

# Task 1: Extraction from reddit
extract_data = PythonOperator(
    task_id='reddit_extraction',
    python_callable=reddit_pipeline,
    op_kwargs={
        'file_name': f'reddit_{file_postfix}',
        'subreddit': 'dataengineering',
        'time_filter': 'day',
        'limit': 100
    },
    dag=dag
)

# Task 2: Upload raw data to s3
upload_data_to_s3 = PythonOperator(
    task_id='raw_data_to_s3',
    python_callable=upload_raw_data_pipeline,
    dag=dag
)

# Task 3: Trigger RAW crawler (after uploading raw data to S3)
trigger_raw_crawler = PythonOperator(
    task_id='trigger_raw_crawler',
    python_callable=trigger_glue_crawler,
    op_kwargs={
        'crawler_name': 'reddit_raw_crawler',
        'region_name': 'af-south-1'
    },
    dag=dag,
)

# Task 4: Upload Glue job script to S3
upload_glue_script = PythonOperator(
    task_id='upload_glue_script',
    python_callable=upload_glue_script_pipeline,
    dag=dag
)

# Task 5: Trigger Glue job to transform data
# The Glue job will read from the raw data S3 bucket and write to the transformed data folder
trigger_glue = PythonOperator(
    task_id='trigger_glue_job',
    python_callable=trigger_glue_job,
    op_kwargs={
        'job_name': 'reddit-glue-job',
        'input_path': f's3://{AWS_DATA_BUCKET_NAME}/raw/',
        'output_path': f's3://{AWS_DATA_BUCKET_NAME}/transformed/'
    },
    do_xcom_push=True,  # 👈 REQUIRED for GlueJobSensor to pull run_id
    dag=dag
)

# Task 6: Wait for Glue job to complete
wait_for_glue_job = GlueJobSensor(
    task_id='wait_for_glue_completion',
    job_name='reddit-glue-job',
    run_id="{{ task_instance.xcom_pull(task_ids='trigger_glue_job', key='return_value') }}",
    aws_conn_id='aws_default',
    poke_interval=60,  # checks every 60 seconds
    timeout=600  # timeout after 10 minutes
)

# Task 7: Trigger TRANSFORMED crawler (after Glue job completes)
trigger_transformed_crawler = PythonOperator(
    task_id='trigger_transformed_crawler',
    python_callable=trigger_glue_crawler,
    op_kwargs={
        'crawler_name': 'reddit_transformed_crawler',
        'region_name': 'af-south-1'
    },
    dag=dag,
)


"""
This creates a Spectrum (external) schema in Redshift.

In terraform/modules/redshift/main.tf, we previously demonstrated how to create
the Redshift Spectrum external schema using Terraform. However, in this case,
we're creating the schema via Airflow.

This approach is useful when you want to create the schema dynamically or manage
it entirely through Airflow instead of Terraform.

Note: Instead of using the master DB user (i.e., the Redshift cluster admin whose
credentials are stored in an SSM parameter), we’ll use a dedicated DB user.
This DB user was created with the master user via Terraform and will be used here
to create the external schema.
"""

# This task waits for the transformed crawler to complete
wait_for_transformed_crawler = GlueCrawlerSensor(
    task_id='wait_for_transformed_crawler',
    crawler_name='reddit_transformed_crawler',
    aws_conn_id='aws_default',
    poke_interval=60,  # Check every 60 seconds
    timeout=600,  # Timeout after 10 minutes
    mode='poke'
)

# This task creates the Spectrum schema in Redshift
create_spectrum_schema = RedshiftDataOperator(
    task_id="create_spectrum_schema",
    cluster_identifier="reddit-cluster",
    database="reddit_database",
    db_user=REDSHIFT_DB_USER,  # Replace with your actual Redshift admin username
    sql=create_schema_sql,
    aws_conn_id="aws_default",
    region="af-south-1"
)

# This tasks validates the creation of the Spectrum schema in Redshift
validate_schema = PythonOperator(
    task_id='validate_schema',
    python_callable=validate_spectrum_schema,
    dag=dag
)

extract_data >> upload_data_to_s3 >> trigger_raw_crawler >> upload_glue_script >> trigger_glue >> wait_for_glue_job >> trigger_transformed_crawler >> wait_for_transformed_crawler >> create_spectrum_schema >> validate_schema
