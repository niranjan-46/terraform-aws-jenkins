# ==============================================================================
# Module: Monitoring (CloudWatch)
# Purpose: Creates CloudWatch alarms and monitoring for Jenkins server
# Commit: feat(monitoring): Provision CloudWatch monitoring and alarms
# ==============================================================================

# ------------------------------------------------------------------------------
# CloudWatch Log Group
# Centralized logging for Jenkins application and system logs
# Commit: feat(monitoring): Create CloudWatch log group for Jenkins
# ------------------------------------------------------------------------------
resource "aws_cloudwatch_log_group" "jenkins" {
  name              = "/jenkins/${var.project_name}-${var.environment}/jenkins-server"
  retention_in_days = 7

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-jenkins-logs"
  })
}

# ------------------------------------------------------------------------------
# CloudWatch Log Group: Docker Logs
# Container logs from Jenkins Docker container
# Commit: feat(monitoring): Create Docker container log group
# ------------------------------------------------------------------------------
resource "aws_cloudwatch_log_group" "docker" {
  name              = "/jenkins/${var.project_name}-${var.environment}/docker"
  retention_in_days = 7

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-docker-logs"
  })
}

# ------------------------------------------------------------------------------
# CloudWatch Alarm: CPU Utilization High
# Alert when CPU usage exceeds 80% for 5 minutes
# Commit: feat(monitoring): Create CPU utilization alarm
# ------------------------------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "${var.project_name}-${var.environment}-cpu-utilization-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors EC2 CPU utilization"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    InstanceId = var.instance_id
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-cpu-alarm"
  })
}

# ------------------------------------------------------------------------------
# CloudWatch Alarm: Memory Utilization High
# Alert when memory usage exceeds 85%
# Commit: feat(monitoring): Create memory utilization alarm
# ------------------------------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "memory_high" {
  alarm_name          = "${var.project_name}-${var.environment}-memory-utilization-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "mem_used_percent"
  namespace           = "CWAgent"
  period              = "300"
  statistic           = "Average"
  threshold           = "85"
  alarm_description   = "This metric monitors memory utilization"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    InstanceId = var.instance_id
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-memory-alarm"
  })
}

# ------------------------------------------------------------------------------
# CloudWatch Alarm: Disk Utilization High
# Alert when root disk usage exceeds 85%
# Commit: feat(monitoring): Create disk utilization alarm
# ------------------------------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "disk_root_high" {
  alarm_name          = "${var.project_name}-${var.environment}-disk-root-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "disk_used_percent"
  namespace           = "CWAgent"
  period              = "300"
  statistic           = "Average"
  threshold           = "85"
  alarm_description   = "This metric monitors root disk utilization"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    InstanceId = var.instance_id
    device     = "/dev/sda1"
    fstype     = "ext4"
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-disk-alarm"
  })
}

# ------------------------------------------------------------------------------
# CloudWatch Alarm: Jenkins Service Down
# Alert when Jenkins container is not running
# Commit: feat(monitoring): Create Jenkins service alarm
# ------------------------------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "jenkins_down" {
  alarm_name          = "${var.project_name}-${var.environment}-jenkins-service-down"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "running"
  namespace           = "CWAgent"
  period              = "60"
  statistic           = "Minimum"
  threshold           = "1"
  alarm_description   = "Alert when Jenkins container is not running"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    InstanceId = var.instance_id
    name       = "jenkins"
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-jenkins-down-alarm"
  })
}

# ------------------------------------------------------------------------------
# CloudWatch Alarm: EBS Volume High IOPS
# Alert when EBS volume IOPS exceed threshold
# Commit: feat(monitoring): Create EBS IOPS alarm
# ------------------------------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "ebs_iops_high" {
  alarm_name          = "${var.project_name}-${var.environment}-ebs-iops-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "VolumeWriteOps"
  namespace           = "AWS/EBS"
  period              = "300"
  statistic           = "Sum"
  threshold           = "10000"
  alarm_description   = "Alert when EBS volume write IOPS are high"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    VolumeId = var.ebs_volume_id
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-ebs-iops-alarm"
  })
}

# ------------------------------------------------------------------------------
# SNS Topic: CloudWatch Alerts
# SNS topic for sending alarm notifications
# Commit: feat(monitoring): Create SNS topic for alarm notifications
# ------------------------------------------------------------------------------
resource "aws_sns_topic" "alerts" {
  name = "${var.project_name}-${var.environment}-alerts"

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-alerts-topic"
  })
}

# ------------------------------------------------------------------------------
# SNS Topic Policy
# Allows CloudWatch to publish to SNS topic
# Commit: feat(monitoring): Configure SNS topic policy for CloudWatch
# ------------------------------------------------------------------------------
resource "aws_sns_topic_policy" "alerts_policy" {
  arn = aws_sns_topic.alerts.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "cloudwatch.amazonaws.com"
      }
      Action = "sns:Publish"
      Resource = aws_sns_topic.alerts.arn
    }]
  })
}