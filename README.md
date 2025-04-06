
# GCP Event-Driven Pipeline con Terraform, GCP y Airflow

Este proyecto implementa una arquitectura en Google Cloud orientada a eventos. Usa Terraform para la infraestructura, Cloud Functions para procesamiento de archivos y un DAG en Apache Airflow para cargar y transformar datos en BigQuery.
La solución como tal recibe archivos CSV con datos (por ejemplo, paises.csv) que se pueden subir manualmente al Cloud Storage. Se procesa esos archivos con una Cloud Function, luego Airflow toma esos archivos y los carga a BigQuery y finalmente, transforma los datos y los guarda en una nueva tabla en BigQuery.

## Arquitectura General

1. Recepción de archivos en un bucket de GCS.
2. Cloud Function se dispara automáticamente al detectar un archivo nuevo.
3. La función procesa el archivo y guarda el resultado en una nueva ruta.
4. Un DAG de Airflow toma los archivos procesados y los carga a BigQuery.
5. Se realiza una transformación en BigQuery y se guarda en una tabla final.

## Estructura del proyecto

.
├── .github/workflows/deploy.yml
|
├── cloud_function/
│   ├── main.py
│   └── requirements.txt
|
├── dags/
│   └── gcs_to_bq_dag.py
|
├── terraform/
│   ├── main.tf
│   ├── variables.tf
│   ├── terraform.tfvars
│   ├── outputs.tf
│   └── provider.tf
|
└── README.md


## Pre-requisitos

- Proyecto activo en Google Cloud
- APIs habilitadas: Cloud Functions, Storage, BigQuery, Composer
    
    gcloud services enable \
        storage.googleapis.com \
        bigquery.googleapis.com \
        cloudfunctions.googleapis.com \
        composer.googleapis.com \
        cloudbuild.googleapis.com \
        artifactregistry.googleapis.com \
        iam.googleapis.com
- Cuenta de servicio con rol "Editor" y key en JSON
- Ejecutar el binding para iam.serviceAccountUser
    gcloud iam service-accounts add-iam-policy-binding wom-p1@appspot.gserviceaccount.com \
    --member="serviceAccount:github-deployer@wom-p1.iam.gserviceaccount.com" \
    --role="roles/iam.serviceAccountUser" \
    --project=wom-p1
- Darle permisos a la cuenta que ejecutará el terraform (usuario@tudominio.com)
    gcloud iam service-accounts add-iam-policy-binding wom-p1@appspot.gserviceaccount.com \
    --member="user:usuario@tudominio.com" \
    --role="roles/iam.serviceAccountUser" \
    --project=wom-p1
- Otros permisos
    gcloud iam service-accounts add-iam-policy-binding wom-p1@appspot.gserviceaccount.com \
    --member="serviceAccount:github-deployer@wom-p1.iam.gserviceaccount.com" \
    --role="roles/iam.serviceAccountUser" \
    --project=wom-p1

    gcloud projects add-iam-policy-binding wom-p1 \
    --member="serviceAccount:github-deployer@wom-p1.iam.gserviceaccount.com" \
    --role="roles/cloudfunctions.developer"

    gcloud projects add-iam-policy-binding wom-p1 \
    --member="serviceAccount:github-deployer@wom-p1.iam.gserviceaccount.com" \
    --role="roles/storage.objectAdmin"

    gcloud projects add-iam-policy-binding wom-p1 \
    --member="serviceAccount:github-deployer@wom-p1.iam.gserviceaccount.com" \
    --role="roles/cloudfunctions.invoker"

    gcloud projects add-iam-policy-binding wom-p1 \
    --member="serviceAccount:github-deployer@wom-p1.iam.gserviceaccount.com" \
    --role="roles/cloudfunctions.developer"

    gcloud iam service-accounts add-iam-policy-binding wom-p1@appspot.gserviceaccount.com \
    --member="serviceAccount:github-deployer@wom-p1.iam.gserviceaccount.com" \
    --role="roles/iam.serviceAccountUser" \
    --project=wom-p1

    gcloud iam service-accounts add-iam-policy-binding \
    --role="roles/iam.serviceAccountUser" \
    --member="user:ruddyguerraarias@gmail.com" \
    projects/wom-p1/serviceAccounts/github-deployer@wom-p1.iam.gserviceaccount.com

    gcloud iam service-accounts add-iam-policy-binding \
    github-deployer@wom-p1.iam.gserviceaccount.com \
    --role="roles/iam.serviceAccountUser" \
    --member="user:ruddyguerraarias@gmail.com" \
    --project=wom-p1


- Para pruebas en local instalar: Terraform, gcloud CLI, GitHub CLI

## 1. Empaquetar la Cloud Function
Ya se encuentra empaquetado pero si se actualiza el código se debe volver a generar manualmente el zip

cd cloud_function
zip -r ../cloud_function.zip .


## 2. Configuración de Terraform

Archivo terraform.tfvars:

project_id    = "wom-p1"
region        = "us-central1"
bucket_name   = "wom-bucket-demo"
function_name = "wom-gcs-trigger-function"
service_account = "github-deployer@wom-p1.iam.gserviceaccount.com"

Inicializa y aplica:

cd terraform
terraform init
terraform apply -auto-approve

## 3. CI/CD con GitHub Actions

El repositorio incluye un workflow en .github/workflows/deploy.yml que automatiza el despliegue de tu infraestructura al hacer push en la rama main. Este workflow ejecuta los comandos de Terraform para crear o actualizar los recursos en Google Cloud Platform (GCP).

Para que el pipeline funcione, necesitas configurar los secrets de autenticación en GitHub.

Crear un secreto en GitHub: Para que GitHub Actions pueda autenticarse con Google Cloud y ejecutar Terraform, necesitas agregar los secretos de Google Cloud a tu repositorio en GitHub. Sigue estos pasos:

1. **Ve a tu repositorio en GitHub**.
2. **Haz clic en "Settings"** (Configuración) en el menú superior.
3. En el menú lateral izquierdo, selecciona **"Secrets and variables"**.
4. Haz clic en Actions
5. Haz clic en el botón **"New repository secret"**.

Luego, agrega los siguientes secretos:

- **`GCP_PROJECT_ID`**: El ID de tu proyecto en Google Cloud.  
  Ejemplo: `wom-p1`.

- **`GCP_SERVICE_ACCOUNT_EMAIL`**: La cuenta de servicio
  Ejemplo: `github-deployer@wom-p1.iam.gserviceaccount.com`.

- **`GCP_CREDENTIALS_JSON`**: El contenido del archivo JSON de la cuenta de servicio de Google Cloud.  
  Para obtener este archivo:
  a. Ve a la **Console de Google Cloud**.
  b. Accede a **IAM & Admin** > **Service Accounts**.
  c. Crea una nueva cuenta de servicio o usa una existente.
  d. Asígnale los roles necesarios: Cloud Functions Admin, Storage Admin, Service Account User
  e. Descarga la clave de la cuenta de servicio en formato JSON.
  f. Copia el contenido del archivo JSON y pégalo en el campo **Value** de GitHub Secrets.

   **Nota:** Hay que mantener este archivo seguro, ya que contiene las credenciales de acceso a tu proyecto de Google Cloud.

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
