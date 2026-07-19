"""
Daily batch orchestration for Nova Retail.

Runs the two batch source producers (supplier catalog, currency rates),
then triggers dbt to rebuild staging -> curated once new data has landed.

    [supplier_catalog]   [currency_rates]
              \\                /
               [dbt run]
                    |
               [dbt test]
"""

from datetime import datetime, timedelta

from airflow import DAG
from airflow.providers.cncf.kubernetes.operators.pod import (
    KubernetesPodOperator,
)

PROJECT_ID = "project-19093238-3ff7-407b-9e3"
REGION = "us-central1"
REPO = "nova-retail-pipelines"

BATCH_PRODUCERS_IMAGE = f"{REGION}-docker.pkg.dev/{PROJECT_ID}/{REPO}/batch-producers:latest"
DBT_IMAGE = f"{REGION}-docker.pkg.dev/{PROJECT_ID}/{REPO}/dbt-nova-retail:latest"

# Composer 2 runs KubernetesPodOperator tasks in this dedicated namespace
NAMESPACE = "composer-user-workloads"

default_args = {
    "owner": "nova-retail",
    "retries": 2,
    "retry_delay": timedelta(minutes=5),
}

with DAG(
    dag_id="nova_retail_batch_pipeline",
    description="Daily batch ingestion + dbt transform for Nova Retail",
    default_args=default_args,
    schedule_interval="@daily",
    start_date=datetime(2026, 7, 1),
    catchup=False,
    tags=["nova-retail", "batch"],
) as dag:

    fetch_supplier_catalog = KubernetesPodOperator(
        task_id="fetch_supplier_catalog",
        name="fetch-supplier-catalog",
        namespace=NAMESPACE,
        image=BATCH_PRODUCERS_IMAGE,
        cmds=["python", "supplier_catalog_generator.py"],
        env_vars={"RAW_ZONE_BUCKET": f"{PROJECT_ID}-raw-zone-dev"},
        get_logs=True,
        is_delete_operator_pod=True,
        config_file="/home/airflow/composer_kube_config",
        kubernetes_conn_id="kubernetes_default",
    )

    fetch_currency_rates = KubernetesPodOperator(
        task_id="fetch_currency_rates",
        name="fetch-currency-rates",
        namespace=NAMESPACE,
        image=BATCH_PRODUCERS_IMAGE,
        cmds=["python", "currency_rates_fetcher.py"],
        env_vars={"RAW_ZONE_BUCKET": f"{PROJECT_ID}-raw-zone-dev"},
        get_logs=True,
        is_delete_operator_pod=True,
        config_file="/home/airflow/composer_kube_config",
        kubernetes_conn_id="kubernetes_default",
    )

    dbt_run = KubernetesPodOperator(
        task_id="dbt_run",
        name="dbt-run",
        namespace=NAMESPACE,
        image=DBT_IMAGE,
        cmds=["dbt", "run", "--profiles-dir", "/root/.dbt"],
        get_logs=True,
        is_delete_operator_pod=True,
        config_file="/home/airflow/composer_kube_config",
        kubernetes_conn_id="kubernetes_default",
    )

    dbt_test = KubernetesPodOperator(
        task_id="dbt_test",
        name="dbt-test",
        namespace=NAMESPACE,
        image=DBT_IMAGE,
        cmds=["dbt", "test", "--profiles-dir", "/root/.dbt"],
        get_logs=True,
        is_delete_operator_pod=True,
        config_file="/home/airflow/composer_kube_config",
        kubernetes_conn_id="kubernetes_default",
    )

    [fetch_supplier_catalog, fetch_currency_rates] >> dbt_run >> dbt_test