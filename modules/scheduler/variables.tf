# ------------------------------
# SCHEDULER MODULE INPUT VARIABLES
# ------------------------------

# Name for the CloudWatch Event Rule (scheduler)
# This name is used to identify the scheduled rule that triggers the Lambda function.
variable "scheduler_name" {
  description = "Name of the CloudWatch Event Rule (e.g., access-key-rotation-scheduler)"
  default     = ""
}

# Cron expression for the CloudWatch Event Rule
# This defines when the Lambda function should be triggered.
# Example: "cron(0 0 * * ? *)" triggers it every day at midnight UTC.
variable "cron_expression" {
  description = "Cron expression defining the schedule for Lambda execution"
  default     = ""
}

# ARN (Amazon Resource Name) of the Lambda function to be triggered
# Used by CloudWatch Events to know which function to invoke.
variable "lambda_arn" {
  description = "ARN of the Lambda function to trigger"
  default     = ""
}

# Name of the Lambda function (for use in targets or permissions)
# This is often required for logging, identification, or adding permissions.
variable "function_name" {
  description = "Name of the Lambda function being scheduled"
  default     = ""
}
