# --------------------------------------------
# GLOBAL SETTINGS
# --------------------------------------------

variable "region" {
  description = "AWS Region to deploy resources into"
  default     = "us-east-1"
}


# --------------------------------------------
# VPC MODULE
# --------------------------------------------

variable "existing_vpc" {
  description = "Set to true to use an existing VPC instead of creating a new one"
  type        = bool
  default     = false
}

variable "vpc_id" {
  description = "ID of the existing VPC (required if existing_vpc is true)"
  type        = string
  default     = ""
}

variable "existing_vpc_cidr" {
  description = "CIDR block of existing VPC (used for lookup/routing rules)"
  default     = ""
}

variable "subnet_id" {
  description = "Subnet ID to place the Lambda function in (used with existing VPC)"
  type        = string
  default     = ""
}

variable "security_group" {
  description = "Security group ID for Lambda function (optional)"
  default     = ""
}

variable "vpc_cidr" {
  description = "CIDR block for the new VPC"
  default     = "10.0.0.0/16"
}

variable "vpc_public_subnet_cidr" {
  description = "CIDR block for public subnet"
  default     = "10.0.1.0/24"
}

variable "vpc_private_subnet_cidr" {
  description = "CIDR block for private subnet"
  default     = "10.0.2.0/24"
}


# --------------------------------------------
# LAMBDA MODULE
# --------------------------------------------

variable "lambda_function_name" {
  description = "Name of the Lambda function"
  default     = "user-access-key-rotater"
}

variable "iam_lambda_role_name" {
  description = "IAM role name for the Lambda function"
  default     = "key-rotater-role"
}

variable "user_skip_tag_key" {
  description = "User tag key used to skip access key rotation"
  default     = "skip"
}

variable "user_skip_tag_value" {
  description = "User tag value used to skip access key rotation"
  default     = "true"
}

variable "account_admin_username" {
  description = "IAM username of the account administrator"
  default     = "User Admin"
}

variable "account_admin_email" {
  description = "Email of the account administrator"
  default     = "admin@example.com"
}

variable "admin_group" {
  description = "IAM Group name for admin users"
  default     = "AdminGroup"
}

variable "max_access_key_age" {
  description = "Age (in days) after which access key must be rotated"
  type        = number
  default     = 90
}

variable "delete_key_age" {
  description = "Age (in days) after which access key should be deleted"
  type        = number
  default     = 100
}


# --------------------------------------------
# SCHEDULER MODULE (CloudWatch Event Rule)
# --------------------------------------------

variable "cloudwatch_event_rule_name" {
  description = "Name of the CloudWatch Event Rule"
  default     = "access_key_scheduler"
}

variable "cloudwatch_event_rule_cron_expression" {
  description = "Cron expression for Lambda execution schedule"
  default     = "cron(0 0 1 * ? *)"
}


# --------------------------------------------
# SES MODULE
# --------------------------------------------

variable "email_addresses" {
  description = "List of email addresses to notify"
  type        = list(string)
  default = [
    "Email1@domain.com",
    "Email2@domain.com"
  ]
}


# --------------------------------------------
# ACM MODULE
# --------------------------------------------

variable "domain" {
  description = "Domain name for ACM certificate"
  type        = string
}

variable "environment" {
  description = "Deployment environment (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"
}


# --------------------------------------------
# CLOUDWATCH ALARMS MODULE
# --------------------------------------------

variable "ec2_instance_id" {
  description = "EC2 instance ID to monitor"
  type        = string
}

variable "rds_instance_id" {
  description = "RDS instance ID to monitor"
  type        = string
}

variable "sns_topic_arn" {
  description = "ARN of the SNS topic to send alarm notifications"
  type        = string
}


# --------------------------------------------
# IAM PASSWORD POLICY MODULE
# --------------------------------------------

variable "minimum_password_length" {
  description = "Minimum length for IAM user passwords"
  type        = number
  default     = 14
}

variable "require_symbols" {
  description = "Require at least one symbol in passwords"
  type        = bool
  default     = true
}

variable "require_numbers" {
  description = "Require at least one number in passwords"
  type        = bool
  default     = true
}

variable "require_uppercase_characters" {
  description = "Require at least one uppercase letter"
  type        = bool
  default     = true
}

variable "require_lowercase_characters" {
  description = "Require at least one lowercase letter"
  type        = bool
  default     = true
}

variable "allow_users_to_change_password" {
  description = "Allow IAM users to change their own password"
  type        = bool
  default     = true
}

variable "max_password_age" {
  description = "Days after which IAM password must be rotated"
  type        = number
  default     = 90
}

variable "password_reuse_prevention" {
  description = "Number of previous passwords IAM users cannot reuse"
  type        = number
  default     = 5
}

variable "hard_expiry" {
  description = "Whether IAM users are denied access after password expires"
  type        = bool
  default     = false
}
