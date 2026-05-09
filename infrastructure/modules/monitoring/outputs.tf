output "log_group_name" {
  value = aws_cloudwatch_log_group.jenkins.name
}

output "sns_topic_arn" {
  value = aws_sns_topic.alerts.arn
}

output "cpu_alarm_name" {
  value = aws_cloudwatch_metric_alarm.cpu_high.alarm_name
}

output "memory_alarm_name" {
  value = aws_cloudwatch_metric_alarm.memory_high.alarm_name
}

output "jenkins_alarm_name" {
  value = aws_cloudwatch_metric_alarm.jenkins_down.alarm_name
}