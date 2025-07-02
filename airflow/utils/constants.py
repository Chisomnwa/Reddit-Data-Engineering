import configparser
import os

parser = configparser.ConfigParser()
parser.read(os.path.join(os.path.dirname(__file__), '..', 'config', 'config.conf'))

CLIENT_SECRET = parser.get('api_keys', 'reddit_secret_key')
CLIENT_ID = parser.get('api_keys', 'reddit_client_id')
USER_AGENT = parser.get('api_keys', 'reddit_user_agent')

DATABASE_HOST = parser.get('database', 'database_host')
DATABASE_NAME = parser.get('database', 'database_name')
DATABASE_PORT = parser.get('database', 'database_port')
DATABASE_USERNAME = parser.get('database', 'database_username')
DATABASE_PASSWORD = parser.get('database', 'database_password')

INPUT_PATH = parser.get('file_paths', 'input_path')
OUTPUT_PATH = parser.get('file_paths', 'output_path')

#AWS
AWS_ACCESS_KEY_ID = parser.get('aws', 'aws_access_key_id')
AWS_SECRET_ACCESS_KEY = parser.get('aws', 'aws_secret_access_key')
AWS_REGION = parser.get('aws', 'aws_region')
AWS_DATA_BUCKET_NAME = parser.get('aws', 'aws_data_bucket_name')
AWS_CODE_BUCKET_NAME = parser.get('aws', 'aws_script_bucket_name')
REDSHIFT_ROLE_ARN = parser.get('aws', 'redshift_role_arn').strip()  # .strip() removes ALL whitespace
REDSHIFT_DB_USER = parser.get('aws', 'redshift_db_user')

POST_FIELDS = (
    'id',
    'title',
    'score',
    'num_comments',
    'author',
    'created_utc',
    'url',
    'over_18',
    'edited',
    'spoiler',
    'stickied',
)
 
