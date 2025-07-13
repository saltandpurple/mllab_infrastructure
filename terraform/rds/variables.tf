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
  type    = string
  default = "16.4"
}

variable "instance_class" {
  type    = string
  default = "db.t3.micro"
}

variable "allocated_storage" {
  type    = number
  default = 10
}

variable "max_allocated_storage" {
  description = "Upper limit for RDS auto-scaling storage"
  type        = number
  default     = 20
}

variable "backup_retention_period" {
  type    = number
  default = 7
}

variable "vpc_name" {
  type = string
}

variable "environment" {
  type = string
}
