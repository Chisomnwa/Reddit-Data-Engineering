import boto3
from botocore.exceptions import ClientError
from utils.constants import AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_REGION

def trigger_glue_crawler(crawler_name, region_name=AWS_REGION):
    """
    Trigger an AWS Glue Crawler using boto3.

    Args:
        crawler_name (str): Name of the Glue crawler.
        region_name (str): AWS region.
    """
    glue = boto3.client(
        'glue',
        region_name=region_name,
        aws_access_key_id=AWS_ACCESS_KEY_ID,
        aws_secret_access_key=AWS_SECRET_ACCESS_KEY
    )

    try:
        response = glue.start_crawler(Name=crawler_name)
        print(f"Crawler '{crawler_name}' triggered successfully: {response}")
    except glue.exceptions.CrawlerRunningException:
        print(f"Crawler '{crawler_name}' is already running. Skipping.")
    except ClientError as e:
        print(f"Unexpected error: {e}")
        raise e  # Fail the task intentionally for real issues

    return "done"  # ✅ Explicit return so Airflow marks task as successful


# def trigger_glue_job(job_name, input_path, output_path, region_name=AWS_REGION):
#     """
#     Trigger an AWS Glue Job using boto3.

#     Args:
#         job_name (str): Name of the Glue job.
#         input_path (str): S3 path to raw data.
#         output_path (str): S3 path for transformed data.
#         region_name (str): AWS region.
#     """
#     glue = boto3.client(
#         'glue',
#         region_name=region_name,
#         aws_access_key_id=AWS_ACCESS_KEY_ID,
#         aws_secret_access_key=AWS_SECRET_ACCESS_KEY
#     )

#     response = glue.start_job_run(
#         JobName=job_name,
#         Arguments={
#             '--input_path': input_path,
#             '--output_path': output_path
#         }
#     )

#     job_run_id = response['JobRunId']
#     print(f"Glue Job triggered. JobRunId: {job_run_id}")
#     return job_run_id

# This particular versiontriggers the AWS Glue job, checking if it's already running to avoid concurrent executions.
def trigger_glue_job(job_name, input_path, output_path, region_name=AWS_REGION):
    """
    Trigger an AWS Glue Job using boto3, unless it's already running.

    Args:
        job_name (str): Name of the Glue job.
        input_path (str): S3 path to raw data.
        output_path (str): S3 path for transformed data.
        region_name (str): AWS region.
    """
    glue = boto3.client(
        'glue',
        region_name=region_name,
        aws_access_key_id=AWS_ACCESS_KEY_ID,
        aws_secret_access_key=AWS_SECRET_ACCESS_KEY
    )

    # Check if there is a currently running job
    try:
        response = glue.get_job_runs(JobName=job_name, MaxResults=5)
        running_job = next(
            (run for run in response['JobRuns']
             if run['JobRunState'] in ['STARTING', 'RUNNING', 'STOPPING']),
            None
        )

        if running_job:
            job_run_id = running_job['Id']
            print(f"Glue job '{job_name}' is already running with JobRunId: {job_run_id}. Skipping new trigger.")
            return job_run_id
    except ClientError as e:
        print(f"Error checking existing job runs: {e}")
        raise e

    # No active job run found, so trigger a new one
    try:
        response = glue.start_job_run(
            JobName=job_name,
            Arguments={
                '--input_path': input_path,
                '--output_path': output_path
            }
        )
        job_run_id = response['JobRunId']
        print(f"Glue Job triggered. JobRunId: {job_run_id}")
        return job_run_id
    except glue.exceptions.ConcurrentRunsExceededException:
        print(f"Concurrent run limit exceeded for Glue job '{job_name}'.")
        raise
    except ClientError as e:
        print(f"Unexpected error while triggering Glue job: {e}")
        raise
