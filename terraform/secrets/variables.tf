variable "mlflow-postgres-pw" {
  type = string
  sensitive = true
  default = "" # required, so the tf plan doesn't fail
}
