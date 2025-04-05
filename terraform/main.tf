resource "google_storage_bucket" "bucket" {
  name     = var.bucket_name
  location = var.region
}

resource "google_storage_bucket_object" "function_source" {
  name   = "function-source.zip"
  bucket = google_storage_bucket.bucket.name
  source = "${path.module}/cloud_function.zip"  # Ruta del archivo fuente
}

resource "google_cloudfunctions_function" "function" {
  name        = var.function_name
  description = "Función que se activa cuando llega un archivo"
  runtime     = "python39"
  entry_point = "hello_gcs"
  source_archive_bucket = google_storage_bucket.bucket.name
  source_archive_object = google_storage_bucket_object.function_source.name
  available_memory_mb   = 128
  region                = var.region
  environment_variables = {}

  event_trigger {
    event_type = "google.storage.object.finalize"  # Evento cuando se agrega un archivo a GCS
    resource   = google_storage_bucket.bucket.name # El bucket que activa la función
  }
}

resource "google_project_iam_member" "invoker" {
  project = var.project_id  # Agrega el parámetro `project` con el ID de tu proyecto
  role    = "roles/cloudfunctions.invoker"
  member  = "allUsers"
}

