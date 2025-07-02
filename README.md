# Reddit Data Pipeline Engineering 🚀
An end-to-end data engineering project that extracts data from Reddit, processes and transforms it through an ETL pipeline orchestrated with Airflow and Celery, and makes it queryable via Amazon Athena and Amazon Redshift using external tables through Redshift Spectrum. The pipeline leverages AWS-native services to store, catalog, and analyze data directly from Amazon S3—without loading it into Redshift itself.

---

## 📌 Project Overview

This project demonstrates a complete ETL pipeline integrating:

- **Reddit API** for data extraction
- **Apache Airflow & Celery** for orchestration and task scheduling
- **PostgreSQL** for metadata handling
- **Amazon S3** for raw and transformed data storage
- **AWS Glue** for data cataloging and transformation
- **Amazon Athena** for intitial exploration of data from S3
- **Amazon Redshift via externa schema and table** for further analytics and reporting

---

## 🛠️ Data Architecture
![image](https://github.com/Chisomnwa/Reddit-Data-Engineering/blob/main/images/reddit_etl_architecture.png)

---
## 🛠️ Tools & Technologies

| Layer | Tools |
|-------|-------|
| Orchestration | Apache Airflow, Celery, Docker |
| Storage | Amazon S3, PostgreSQL |
| Processing | AWS Glue, Athena |
| Data Warehouse | Amazon Redshift |
| Infrastructure | Terraform |
| Programming | Python (with PRAW, Pandas, NumPy, etc.) |

---

## ⚙️ Features

- ✅ Modular Terraform scripts to provision VPC, S3, Glue, Athena, Redshift, IAM, and SSM.
- ✅ Dockerized Airflow with custom Python dependencies.
- ✅ Parameterized and dynamic DAG execution.
- ✅ Glue job and crawler triggering from within Airflow.
- ✅ Raw and transformed data cataloged via AWS Glue crawlers.
- ✅ Data queried via Athena and via external tables (spectrum) in Redshift.

---

## 🧪 DAG Workflow

1. **Extract** posts from the `dataengineering` subreddit.
2. **Upload raw data** to S3.
3. **Trigger Glue crawler** for raw data.
4. **Upload Glue script** and **trigger Glue job** to transform data.
5. **Trigger crawler** for transformed data.
6. **Query transformed data** using Redshift Spectrum (no need to load data into Redshift).

---
## 📦 Setup Instructions

> ⚠️ Ensure you have AWS credentials configured (`aws configure`) and Docker installed.

1. **Clone the repo**
   ```bash
   git clone https://github.com/your-username/Reddit-Data-Engineering.git
   cd Reddit-Data-Engineering

2. **Set up Python virtual environment**
   ```bash
   python -m venv my_venv

   source my_venv/bin/activate  # or my_venv\Scripts\activate on Windows

3. **Install dependencies**
   ```bash
   pip install -r airflow/requirements.txt

4. **Rename the configuration file and the credentials to the file.**
   ```bash
   mv config/config.conf.example config/config.conf

3. **Build and run Airflow in Docker**
   ```bash
   cd airflow
   docker compose up -d

4. **Access Airflow UI**
   ```bash
   http://localhost:8080
   Username: airflow
   Password: airflow

## 📍 Future Improvements
- Add tests under the tests/ folder

- Build CI/CD for Terraform and DAG deployment

- Integrate monitoring (e.g., Prometheus or AWS CloudWatch)

- Add unit and integration tests

## 📖 Medium Article
📖 Medium Article
👉 Check out the full walkthrough in the accompanying Medium article: [Link here]
