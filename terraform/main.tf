# Recurso para crear un bucket en Google Cloud Storage
resource "google_storage_bucket" "bucket" {
  name     = var.bucket_name  # Nombre del bucket
  location = var.region       # Región
}

# Recurso para subir el código fuente de la Cloud Function al bucket de GCS
resource "google_storage_bucket_object" "function_source" {
  name   = "function-source.zip"            
  bucket = google_storage_bucket.bucket.name  
  source = "../cloud_function.zip"
}

# Recurso para crear la Cloud Function
resource "google_cloudfunctions_function" "function" {
  name        = var.function_name
  description = "Función que se activa cuando llega un archivo"
  runtime     = "python311"
  entry_point = "hello_gcs"
  source_archive_bucket = google_storage_bucket.bucket.name
  source_archive_object = google_storage_bucket_object.function_source.name
  available_memory_mb   = 128
  region                = var.region
  environment_variables = {}

  # Configuración de la cuenta de servicio directamente aquí
  service_account_email = var.service_account_cf

  event_trigger {
    event_type = "google.storage.object.finalize"
    resource   = google_storage_bucket.bucket.name
  }
}

# Recurso para dar permisos de invocación a todos los usuarios
resource "google_cloudfunctions_function_iam_member" "invoker" {
  project        = var.project_id
  region         = "us-central1"
  cloud_function = google_cloudfunctions_function.function.name
  role   = "roles/cloudfunctions.invoker"
  member = "allUsers"
}

# Recurso para subir el archivo DAG a GCS, necesario para la integración con Airflow
resource "google_storage_bucket_object" "dag_file" {
  name   = "gcs_to_bq_dag.py"  # Nombre del archivo DAG en GCS
  bucket = google_storage_bucket.bucket.name  # El bucket donde se subirá el archivo
  source = "../dags/gcs_to_bq_dag.py"  # Ruta local del archivo DAG
}
