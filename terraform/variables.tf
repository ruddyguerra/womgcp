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

