import boto3
from etls.aws_etl import connect_to_s3, create_bucket_if_not_exist, upload_to_s3
from utils.constants import AWS_DATA_BUCKET_NAME, AWS_CODE_BUCKET_NAME, AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_REGION
# Edit the config.conf and constants.py script to add the bucket name after provisioning 


def upload_raw_data_pipeline(ti):
    file_path = ti.xcom_pull(task_ids='reddit_extraction', key='return_value')

    s3 = connect_to_s3()
    create_bucket_if_not_exist(s3, AWS_DATA_BUCKET_NAME)
    upload_to_s3(s3, file_path, AWS_DATA_BUCKET_NAME, file_path.split('/')[-1])

def upload_glue_script_pipeline():
    """
    Upload the Glue PySpark script to the code bucket.
    """
    local_script_path = 'glue_jobs/pyspark_script.py'
    s3_key = 'scripts/pyspark_script.py'  # destination in the script bucket

    s3 = boto3.client(
        's3',
        aws_access_key_id=AWS_ACCESS_KEY_ID,
        aws_secret_access_key=AWS_SECRET_ACCESS_KEY,
        region_name=AWS_REGION
    )

    try:
        s3.upload_file(local_script_path, AWS_CODE_BUCKET_NAME, s3_key)
        print(f"Glue script uploaded to s3://{AWS_CODE_BUCKET_NAME}/{s3_key}")
    except Exception as e:
        print(f"Error uploading Glue script: {e}")
