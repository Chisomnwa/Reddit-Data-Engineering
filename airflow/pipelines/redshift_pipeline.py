import os
from airflow.exceptions import AirflowException
from airflow.providers.amazon.aws.hooks.redshift_data import RedshiftDataHook

def validate_spectrum_schema():
    """Validate the creation of the Spectrum schema in Redshift."""
    hook = RedshiftDataHook(aws_conn_id='aws_default')
    result = hook.execute_query(
        "SELECT 1 FROM svv_external_schemas WHERE schemaname = 'spectrum_schema'",
        cluster_identifier='reddit-cluster',
        database='reddit_database'
    )
    if not result:
        raise AirflowException("Spectrum schema not created successfully")


def load_sql_from_volume(sql_dir="/opt/airflow/sql", placeholders=None):
    """
    Load all .sql files from a mounted Docker volume directory (e.g., /opt/airflow/sql).

    Args:
        sql_dir (str): Path to directory containing .sql files.
        placeholders (dict, optional): Placeholder values to inject into SQL scripts.

    Returns:
        dict: Dictionary with filenames as keys and SQL content as values.
    """
    sql_statements = {}

    for filename in os.listdir(sql_dir):
        if filename.endswith(".sql"):
            full_path = os.path.join(sql_dir, filename)
            with open(full_path, "r") as file:
                sql = file.read()

                # Replace placeholders if present
                if placeholders:
                    try:
                        sql = sql.format(**placeholders)
                    except KeyError as e:
                        raise KeyError(f"Missing placeholder for {e} in {filename}")

                sql_statements[filename] = sql

    return sql_statements
