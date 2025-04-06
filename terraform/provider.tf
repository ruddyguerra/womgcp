provider "google" {
  credentials = var.service_account
  project     = var.project_id
  region      = var.region
}
