FROM apache/airflow:3.0.2-python3.11

USER root
RUN apt-get update && apt-get install -y gcc python3-dev

USER airflow

COPY requirements.txt /opt/airflow/
RUN pip install --no-cache-dir -r /opt/airflow/requirements.txt