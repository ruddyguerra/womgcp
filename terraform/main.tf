# Recurso para crear un bucket en Google Cloud Storage
resource "google_storage_bucket" "bucket" {
  name     = var.bucket_name  # Nombre del bucket
  location = var.region       # Región
}

# Recurso para subir el código fuente de la Cloud Function al bucket de GCS
resource "google_storage_bucket_object" "function_source" {
  name   = "function-source.zip"            # Nombre del archivo en GCS
  bucket = google_storage_bucket.bucket.name  # El bucket al que se subirá el archivo
  source = "${path.module}/cloud_function.zip"  # Ruta local del archivo comprimido de la Cloud Function
}

# Recurso para crear la Cloud Function
resource "google_cloudfunctions_function" "function" {
  name        = var.function_name            # Nombre de la Cloud Function
  description = "Función que se activa cuando llega un archivo"  
  runtime     = "python311"                   # Runtime de la función
  entry_point = "hello_gcs"                   # Punto de entrada de la función
  source_archive_bucket = google_storage_bucket.bucket.name  # El bucket donde está el código comprimido
  source_archive_object = google_storage_bucket_object.function_source.name  # El archivo comprimido con el código fuente

  available_memory_mb   = 128  # Memoria asignada a la función (en MB)
  region                = var.region  # Región donde se desplegará la función
  environment_variables = {}  # Variables de entorno (puedes agregar aquí las necesarias)

  # Configuración del trigger (evento) para activar la función
  event_trigger {
    event_type = "google.storage.object.finalize"  # Evento cuando se agrega un archivo a GCS
    resource   = google_storage_bucket.bucket.name  # El bucket que activa la función
  }
}

# Recurso para dar permisos de invocación a todos los usuarios
resource "google_project_iam_member" "invoker" {
  project = var.project_id  # ID del proyecto en GCP
  role    = "roles/cloudfunctions.invoker"  # Rol que permite invocar la función
  member  = "allUsers"  # Los permisos se conceden a todos los usuarios
}

# Recurso para subir el archivo DAG a GCS, necesario para la integración con Airflow
resource "google_storage_bucket_object" "dag_file" {
  name   = "gcs_to_bq_dag.py"  # Nombre del archivo DAG en GCS
  bucket = google_storage_bucket.bucket.name  # El bucket donde se subirá el archivo
  source = "${path.module}/dags/gcs_to_bq_dag.py"  # Ruta local del archivo DAG
}
