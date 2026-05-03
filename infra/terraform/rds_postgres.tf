locals {
  tags = {
    Service     = "biomarker-data-platform"
    Environment = var.environment
    Owner       = "database-engineering"
    ManagedBy   = "terraform"
  }
}

resource "aws_db_parameter_group" "postgres" {
  name        = "${var.db_identifier}-params"
  family      = "postgres16"
  description = "PostgreSQL parameters for DBA exercise observability"

  parameter {
    name  = "shared_preload_libraries"
    value = "pg_stat_statements,auto_explain"
  }

  parameter {
    name  = "log_min_duration_statement"
    value = "1000"
  }

  parameter {
    name  = "log_lock_waits"
    value = "1"
  }

  parameter {
    name  = "auto_explain.log_min_duration"
    value = "500"
  }

  parameter {
    name  = "auto_explain.log_analyze"
    value = "1"
  }

  parameter {
    name  = "auto_explain.log_buffers"
    value = "1"
  }

  tags = local.tags
}

resource "aws_db_instance" "postgres" {
  identifier                   = var.db_identifier
  engine                       = "postgres"
  engine_version               = "16"
  instance_class               = var.db_instance_class
  allocated_storage            = var.db_allocated_storage
  db_name                      = var.db_name
  username                     = var.db_username
  password                     = var.db_password
  db_subnet_group_name         = var.db_subnet_group_name
  vpc_security_group_ids       = var.vpc_security_group_ids
  parameter_group_name         = aws_db_parameter_group.postgres.name
  storage_encrypted            = true
  backup_retention_period      = 7
  monitoring_interval          = 60
  performance_insights_enabled = true
  deletion_protection          = true
  skip_final_snapshot          = false

  enabled_cloudwatch_logs_exports = [
    "postgresql",
    "upgrade"
  ]

  tags = local.tags
}
