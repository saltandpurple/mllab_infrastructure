variable "mlflow-postgres-pw" {
  type = string
  sensitive = true
  default = "" # required, so the tf plan doesn't fail
}

variable "mlflow-admin-pw" {
  type = string
  sensitive = true
  default = "" # required, so the tf plan doesn't fail
  description = "Password for MLflow admin user"
}

variable "mlflow-admin-user" {
  type = string
  sensitive = true
  default = "admin" # default admin username
  description = "Username for MLflow admin access"
}

variable "mlflow-flask-server-secret-key" {
  type = string
  sensitive = true
  default = "" # required, so the tf plan doesn't fail
  description = "Secret key for Flask server in MLflow"
}
