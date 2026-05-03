resource "aws_cloudwatch_metric_alarm" "rds_high_cpu" {
  alarm_name          = "${var.db_identifier}-high-cpu"
  alarm_description   = "RDS CPU is high for a sustained period."
  namespace           = "AWS/RDS"
  metric_name         = "CPUUtilization"
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 3
  threshold           = 80
  comparison_operator = "GreaterThanThreshold"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.postgres.id
  }

  tags = local.tags
}

resource "aws_cloudwatch_metric_alarm" "rds_high_connections" {
  alarm_name          = "${var.db_identifier}-high-connections"
  alarm_description   = "RDS connections are approaching saturation."
  namespace           = "AWS/RDS"
  metric_name         = "DatabaseConnections"
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 3
  threshold           = 400
  comparison_operator = "GreaterThanThreshold"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.postgres.id
  }

  tags = local.tags
}

resource "aws_cloudwatch_metric_alarm" "rds_read_latency" {
  alarm_name          = "${var.db_identifier}-read-latency"
  alarm_description   = "RDS read latency is elevated."
  namespace           = "AWS/RDS"
  metric_name         = "ReadLatency"
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 3
  threshold           = 0.05
  comparison_operator = "GreaterThanThreshold"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.postgres.id
  }

  tags = local.tags
}

resource "aws_cloudwatch_metric_alarm" "rds_write_latency" {
  alarm_name          = "${var.db_identifier}-write-latency"
  alarm_description   = "RDS write latency is elevated."
  namespace           = "AWS/RDS"
  metric_name         = "WriteLatency"
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 3
  threshold           = 0.05
  comparison_operator = "GreaterThanThreshold"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.postgres.id
  }

  tags = local.tags
}
