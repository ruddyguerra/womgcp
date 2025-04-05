
# GCP Event-Driven Pipeline con Terraform, Cloud Functions y Airflow

Este proyecto implementa una arquitectura en Google Cloud orientada a eventos. Usa Terraform para la infraestructura, Cloud Functions para procesamiento de archivos y un DAG en Apache Airflow para cargar y transformar datos en BigQuery.

## Arquitectura General

1. Recepción de archivos en un bucket de GCS.
2. Cloud Function se dispara automáticamente al detectar un archivo nuevo.
3. La función procesa el archivo y guarda el resultado en una nueva ruta.
4. Un DAG de Airflow toma los archivos procesados y los carga a BigQuery.
5. Se realiza una transformación en BigQuery y se guarda en una tabla final.

## Estructura del proyecto

.
├── .github/workflows/deploy.yml
├── cloud_function/
│   ├── main.py
│   └── requirements.txt
├── dags/
│   └── gcs_to_bq_dag.py
├── terraform/
│   ├── main.tf
│   ├── variables.tf
│   ├── terraform.tfvars
│   ├── outputs.tf
│   └── provider.tf
└── README.md


## Pre-requisitos

- Proyecto activo en Google Cloud
- APIs habilitadas: Cloud Functions, Storage, BigQuery, Composer
- Cuenta de servicio con rol "Editor" y key en JSON
- Instalar: Terraform, gcloud CLI, GitHub CLI

## 1. Empaquetar la Cloud Function

cd cloud_function
zip -r ../cloud_function.zip .


## 2. Configuración de Terraform

Archivo terraform.tfvars:

project_id    = "tu-proyecto"
region        = "us-central1"
bucket_name   = "event-driven-bucket"
function_name = "gcs-trigger-function"

Inicializa y aplica:

cd terraform
terraform init
terraform apply -auto-approve

## 3. CI/CD con GitHub Actions

El repositorio incluye un workflow `.github/workflows/deploy.yml` que ejecuta `terraform apply` al hacer push en `main`.

Crea un secreto en GitHub: Para que GitHub Actions pueda autenticarse con Google Cloud y ejecutar Terraform, necesitas agregar los secretos de Google Cloud a tu repositorio en GitHub. Sigue estos pasos:

1. **Ve a tu repositorio en GitHub**.
2. **Haz clic en "Settings"** (Configuración) en el menú superior.
3. En el menú lateral izquierdo, selecciona **"Secrets"**.
4. Haz clic en el botón **"New repository secret"**.

Luego, agrega los siguientes secretos:

- **`GCP_PROJECT_ID`**: El ID de tu proyecto en Google Cloud.  
  Ejemplo: `my-gcp-project-id`.

- **`GCP_CREDENTIALS_JSON`**: El contenido del archivo JSON de la cuenta de servicio de Google Cloud.  
  Para obtener este archivo:
  a. Ve a la **Console de Google Cloud**.
  b. Accede a **IAM & Admin** > **Service Accounts**.
  c. Crea una nueva cuenta de servicio con los permisos adecuados (por ejemplo, **Editor**).
  d. Descarga la clave de la cuenta de servicio en formato JSON.
  e. Copia el contenido del archivo JSON y pégalo en el campo **Value** de GitHub Secrets.

   **Nota:** Asegúrate de mantener este archivo seguro, ya que contiene las credenciales de acceso a tu proyecto de Google Cloud.

5. Haz clic en **"Add secret"** para cada secreto.

Una vez configurados estos secretos, GitHub Actions podrá autenticarse y ejecutar el pipeline de Terraform.

## 4. Ejecutar el DAG en Composer

Sube el DAG:

gsutil cp dags/gcs_to_bq_dag.py gs://<tu-bucket-composer>/dags/

Activa el DAG desde la UI de Airflow o por CLI:

gcloud composer environments run <tu-env> \
  --location us-central1 \
  dags trigger -- gcs_to_bq_pipeline

## Limpieza

terraform destroy -auto-approve

## Notas

- El DAG trabaja con archivos CSV en la carpeta `processed/` del bucket
- BigQuery debe tener la tabla de destino creada o el DAG la debe crear
- Todo es parametrizable y adaptado a tu entorno
