resource "aws_cloudwatch_metric_alarm" "ec2_cpu_utilization" {
  alarm_name          = "EC2HighCPUUtilization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This alarm triggers when CPU > 80% for 10 mins"
  dimensions = {
    InstanceId = var.ec2_instance_id
  }
  alarm_actions = [var.sns_topic_arn]
}

resource "aws_cloudwatch_metric_alarm" "rds_cpu_utilization" {
  alarm_name          = "RDSHighCPUUtilization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This alarm triggers when RDS CPU > 80%"
  dimensions = {
    DBInstanceIdentifier = var.rds_instance_id
  }
  alarm_actions = [var.sns_topic_arn]
}