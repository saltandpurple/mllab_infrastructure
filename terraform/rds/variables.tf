variable "db_identifier" {
  type = string
}

variable "db_name" {
  type = string
}

variable "db_username" {
  type = string
}

variable "db_password" {
  type      = string
  sensitive = true
}

variable "engine_version" {
  type = string
}

variable "instance_class" {
  type = string
}

variable "allocated_storage" {
  type = number
}

variable "max_allocated_storage" {
  description = "Upper limit for RDS auto-scaling storage"
  type        = number
}

variable "backup_retention_period" {
  type = number
}

variable "vpc_id" {
  type = string
}

variable "environment" {
  type = string
}
