from airflow import DAG
from airflow.providers.google.cloud.transfers.gcs_to_bigquery import GCSToBigQueryOperator
from airflow.providers.google.cloud.operators.bigquery import BigQueryInsertJobOperator
from datetime import datetime

# Parámetros del entorno (ajustables)
PROJECT_ID = "tu-proyecto"
DATASET = "mi_dataset"
TABLE_RAW = "mi_tabla_raw"
TABLE_FINAL = "mi_tabla_final"
BUCKET_NAME = "event-driven-bucket-demo"
SOURCE_OBJECTS = ["processed/*.csv"]

# Configuración por defecto del DAG
default_args = {
    "owner": "airflow",
    "start_date": datetime(2024, 1, 1),
    "retries": 1,
}

# Definición del DAG
with DAG(
    dag_id="gcs_to_bq_pipeline",
    default_args=default_args,
    description="Carga datos desde GCS a BigQuery y los transforma",
    schedule_interval=None,  # Se puede activar por trigger externo
    catchup=False,
    tags=["gcp", "bigquery", "gcs", "etl"],
) as dag:

    # Tarea 1: Cargar datos desde GCS a una tabla RAW en BigQuery
    load_to_bq = GCSToBigQueryOperator(
        task_id="load_from_gcs",
        bucket=BUCKET_NAME,
        source_objects=SOURCE_OBJECTS,
        destination_project_dataset_table=f"{PROJECT_ID}.{DATASET}.{TABLE_RAW}",
        schema_fields=[
            {"name": "nombre", "type": "STRING", "mode": "NULLABLE"},
            {"name": "valor", "type": "INTEGER", "mode": "NULLABLE"},
        ],
        skip_leading_rows=1,
        source_format="CSV",
        write_disposition="WRITE_TRUNCATE",
    )

    # Tarea 2: Ejecutar una transformación y guardar en tabla final
    transform_data = BigQueryInsertJobOperator(
        task_id="transform_data",
        configuration={
            "query": {
                "query": f"""
                    CREATE OR REPLACE TABLE `{PROJECT_ID}.{DATASET}.{TABLE_FINAL}` AS
                    SELECT 
                        nombre, 
                        valor * 2 AS valor_doble
                    FROM `{PROJECT_ID}.{DATASET}.{TABLE_RAW}`
                """,
                "useLegacySql": False,
            }
        },
    )

    # Dependencias
    load_to_bq >> transform_data
