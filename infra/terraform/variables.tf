variable "aws_region" {
  description = "AWS region for the example RDS resources."
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Deployment environment tag."
  type        = string
  default     = "exercise"
}

variable "db_identifier" {
  description = "RDS instance identifier."
  type        = string
  default     = "everlywell-dba-exercise-postgres"
}

variable "db_instance_class" {
  description = "RDS instance size."
  type        = string
  default     = "db.t4g.medium"
}

variable "db_allocated_storage" {
  description = "Allocated storage in GB."
  type        = number
  default     = 100
}

variable "db_name" {
  description = "Initial database name."
  type        = string
  default     = "everlywell"
}

variable "db_username" {
  description = "Database master username for the example."
  type        = string
  default     = "everly_admin"
}

variable "db_password" {
  description = "Database master password. Use Secrets Manager or CI variables in real deployments."
  type        = string
  sensitive   = true
}

variable "db_subnet_group_name" {
  description = "Existing DB subnet group name."
  type        = string
}

variable "vpc_security_group_ids" {
  description = "Security groups allowed to access the database."
  type        = list(string)
}

variable "datadog_enabled" {
  description = "Whether Datadog monitor examples should be created."
  type        = bool
  default     = false
}
