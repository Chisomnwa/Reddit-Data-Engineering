# Just to drop a comment.

# A better approach I could have used is just create a function that uoploads the extracted data to S3 using Boto3 session.
# The function will inherit the extract data function that extracts the data from the reddit API.
# But I wanted to use the s3fs library to show how to use it.
# This is a simple script to upload data to S3 using s3fs.
# s3fs is a Python library that provides a convenient interface to interact with S3 buckets
# using the filesystem interface. It allows you to read and write files directly to S3 as if they were local files.

# So, the below process is better if you are sure the bucket isn't existing or if you aren't using terraform for the 
# provisioning of resources.

import s3fs
from utils.constants import AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY 

def connect_to_s3():
    try:
        s3 = s3fs.S3FileSystem(anon=False,
                               key=AWS_ACCESS_KEY_ID,
                               secret=AWS_SECRET_ACCESS_KEY)
        return s3
    except Exception as e:
        print(e)


def create_bucket_if_not_exist(s3: s3fs.S3FileSystem, bucket_name: str):
    try:
        """
        Create an S3 bucket if it does not exist.
        
        Args:
            s3 (s3fs.S3FileSystem): An instance of S3FileSystem.
            bucket_name (str): The name of the S3 bucket to create.
        """
        if not s3.exists(bucket_name):
            s3.mkdir(bucket_name)
            print(f"Bucket {bucket_name} created.")
        else:
            print(f"Bucket {bucket_name} already exists.")
    except Exception as e:
        print(f"Error creating bucket {bucket_name}: {e}")


def upload_to_s3(s3: s3fs.S3FileSystem, file_path: str, bucket_name: str, s3_file_name: str):
    """
    Upload a file to an S3 bucket.
    
    Args:
        s3 (s3fs.S3FileSystem): An instance of S3FileSystem.
        file_path (str): The local path of the file to upload.
        bucket_name (str): The name of the S3 bucket.
        s3_file_name (str): The name of the file in S3.
    """
    try:
        s3.put(file_path, bucket_name + '/raw/' + s3_file_name)
        print("File uploaded successfully to S3.")
    except FileNotFoundError:
        print('The file was not found.')