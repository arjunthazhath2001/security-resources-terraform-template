# ID of the EC2 instance to monitor
variable "ec2_instance_id" {
  type        = string
  description = "The ID of the EC2 instance to monitor with CloudWatch"
}

# ID of the RDS instance to monitor
variable "rds_instance_id" {
  type        = string
  description = "The ID of the RDS instance to monitor with CloudWatch"
}

# ARN of the SNS topic to send alarm notifications
variable "sns_topic_arn" {
  type        = string
  description = "SNS topic ARN for CloudWatch alarm notifications"
}
