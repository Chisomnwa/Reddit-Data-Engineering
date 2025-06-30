import os
import sys
from datetime import datetime, timedelta

# Airflow imports
from airflow import DAG
from airflow.providers.standard.operators.python import PythonOperator
from airflow.providers.amazon.aws.operators.redshift_data import RedshiftDataOperator
from airflow.providers.amazon.aws.transfers.s3_to_redshift import S3ToRedshiftOperator
from airflow.providers.amazon.aws.sensors.glue import GlueJobSensor

# Custom module imports
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from pipelines.reddit_pipeline import reddit_pipeline
from pipelines.aws_s3_pipeline import upload_raw_data_pipeline, upload_glue_script_pipeline
from utils.constants import AWS_DATA_BUCKET_NAME
from pipelines.glue_pipeline import trigger_glue_job, trigger_glue_crawler

# Define DAG folder path for mounted Docker volume
# dag_folder = "/opt/airflow/sql"
# sql_file = "create_table.sql"  
# This above two lines work if the sql folder is in the dags folder which is where the RedshiftDataOperator searches for it.
# But in this case, the sql folder is mounted as a volume in the container at /opt/airflow/sql, 
# which is not the dags folder. So, we need to read in sql file directly from the mounted path.

with open("/opt/airflow/sql/create_table.sql", "r") as f:
    create_table_sql = f.read()

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
    # region_name='af-south-1',
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

# TTask 8: To validate the data in Redshift after transformation
validate_external_query = RedshiftDataOperator(
    task_id = "validate_external_query",
    cluster_identifier="reddit-cluster",
    database="reddit_database",
    sql="SELECT COUNT(*) FROM spectrum_schema.reddit_transformed;",
    aws_conn_id="aws_default",
    wait_for_completion=True,
    region="af-south-1"
)

extract_data >> upload_data_to_s3 >> trigger_raw_crawler >> upload_glue_script >> trigger_glue >> wait_for_glue_job >> trigger_transformed_crawler


