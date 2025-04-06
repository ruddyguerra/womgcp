variable "project_id" {
  description = "Project ID"
  type        = string
}

variable "bucket_name" {
  description = "El nombre del bucket"
  type        = string
}

variable "function_name" {
  description = "El nombre de la función"
  type        = string
}

variable "region" {
  description = "La región"
  type        = string
  default     = "us-central1"
}

variable "service_account" {
  description = "Cuenta de servicio"
  type        = string
  default     = "github-deployer@wom-p1.iam.gserviceaccount.com"
}

variable "service_account_cf" {
  description = "Cuenta de servicio"
  type        = string
}

