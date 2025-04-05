from airflow import DAG
from airflow.providers.google.cloud.transfers.gcs_to_bigquery import GCSToBigQueryOperator
from airflow.providers.google.cloud.operators.bigquery import BigQueryInsertJobOperator
from datetime import datetime

# Parámetros del entorno (ajustables)
PROJECT_ID = "wom-p1"
DATASET = "ds_paises"
TABLE_RAW = "paises_raw"
TABLE_FINAL = "paises_agrupado"
BUCKET_NAME = "wom-bucket-demo"
SOURCE_OBJECTS = ["processed/paises.csv"]

# Configuración por defecto del DAG
default_args = {
    "owner": "airflow",
    "start_date": datetime(2024, 1, 1),
    "retries": 1,
}

# Definición del DAG
with DAG(
    dag_id="paises_gcs_to_bq_pipeline",
    default_args=default_args,
    description="Carga y transforma archivo de países desde GCS a BigQuery",
    schedule_interval=None,
    catchup=False,
    tags=["gcp", "bigquery", "gcs", "etl", "paises"],
) as dag:

    # Tarea 1: Cargar CSV desde GCS a tabla raw en BigQuery
    load_to_bq = GCSToBigQueryOperator(
        task_id="load_from_gcs",
        bucket=BUCKET_NAME,
        source_objects=SOURCE_OBJECTS,
        destination_project_dataset_table=f"{PROJECT_ID}.{DATASET}.{TABLE_RAW}",
        schema_fields=[
            {"name": "pais", "type": "STRING", "mode": "NULLABLE"},
            {"name": "estado", "type": "STRING", "mode": "NULLABLE"},
        ],
        skip_leading_rows=1,
        source_format="CSV",
        write_disposition="WRITE_TRUNCATE",
    )

    # Tarea 2: Transformar datos (ejemplo: contar estados por país)
    transform_data = BigQueryInsertJobOperator(
        task_id="transform_data",
        configuration={
            "query": {
                "query": f"""
                    CREATE OR REPLACE TABLE `{PROJECT_ID}.{DATASET}.{TABLE_FINAL}` AS
                    SELECT 
                        pais, 
                        COUNT(estado) AS cantidad_estados
                    FROM `{PROJECT_ID}.{DATASET}.{TABLE_RAW}`
                    GROUP BY pais
                """,
                "useLegacySql": False,
            }
        },
    )

    # Dependencias
    load_to_bq >> transform_data
