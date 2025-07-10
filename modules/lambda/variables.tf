# ------------------------------
# VPC CONFIGURATION FOR LAMBDA
# ------------------------------

# The ID of the VPC where the Lambda function will be deployed.
variable "vpc_id" {
  description = "VPC ID where the Lambda function will be deployed"
  default     = ""
}

# The ID of the subnet inside the VPC where the Lambda function will run.
variable "subnet_id" {
  description = "Subnet ID for the Lambda function inside the VPC"
  type        = string
  default     = ""
}

# Security group ID to associate with the Lambda function
variable "security_group" {
  description = "Security Group ID for the Lambda function (optional)"
  default     = ""
}

# CIDR block of the VPC (used for networking logic inside Lambda, e.g. allow rules)
variable "vpc_cidr" {
  description = "CIDR block of the VPC for reference"
  default     = ""
}

# ------------------------------
# LAMBDA FUNCTION IDENTIFICATION
# ------------------------------

# Name to assign to the Lambda function
variable "function_name" {
  description = "Name of the Lambda function"
  default     = ""
}

# Name of the IAM role to be used by the Lambda function
variable "function_role_name" {
  description = "IAM role name for Lambda function execution"
  default     = ""
}

# ------------------------------
# ACCESS KEY ROTATION SETTINGS
# ------------------------------

# Maximum age (in days) after which an access key should be rotated
variable "max_key_age" {
  description = "Maximum age (in days) before an access key should be rotated"
  default     = ""
}

# Age (in days) after which the access key should be deleted (if not rotated)
variable "expire_key_age" {
  description = "Age (in days) after which access key should be deleted"
  default     = ""
}

# ------------------------------
# USER TAG FILTERS FOR SKIPPING ROTATION
# ------------------------------

# Tag key to look for when deciding if a user should be skipped (e.g. "skip")
variable "tag_key" {
  description = "Tag key to identify users to skip from rotation (e.g. 'skip')"
  default     = ""
}

# Tag value associated with the above key to confirm skip (e.g. "true")
variable "tag_value" {
  description = "Tag value indicating user should be skipped (e.g. 'true')"
  default     = ""
}

# ------------------------------
# ADMIN METADATA
# ------------------------------

# IAM username of the administrator (used for alerts, exclusions, etc.)
variable "admin_username" {
  description = "IAM username of the administrator"
  default     = ""
}

# Email address of the administrator to send alerts to (SES or SNS)
variable "admin_email" {
  description = "Admin's email address for notifications"
  default     = ""
}

# IAM group name that contains admin users (could be used to exclude from rotation)
variable "admin_group_name" {
  description = "Admin IAM group name whose users may be excluded from key rotation"
  default     = ""
}
