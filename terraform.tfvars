# ------------------------------
# GLOBAL SETTINGS
# ------------------------------
region = "us-east-1"

# ------------------------------
# VPC MODULE
# ------------------------------
existing_vpc         = false
vpc_id               = ""                         # Only if existing_vpc = true
existing_vpc_cidr    = ""                         # Only if existing_vpc = true
subnet_id            = ""                         # Only if existing_vpc = true
security_group       = ""                         # Optional

vpc_cidr             = "10.0.0.0/16"
vpc_public_subnet_cidr  = "10.0.1.0/24"
vpc_private_subnet_cidr = "10.0.2.0/24"

# ------------------------------
# LAMBDA MODULE
# ------------------------------
lambda_function_name   = "user-access-key-rotater"
iam_lambda_role_name   = "key-rotater-role"
user_skip_tag_key      = "skip"
user_skip_tag_value    = "true"
account_admin_username = "User Admin"
account_admin_email    = "admin@example.com"
admin_group            = "AdminGroup"
max_access_key_age     = 90
delete_key_age         = 100

# ------------------------------
# SCHEDULER MODULE
# ------------------------------
cloudwatch_event_rule_name            = "access_key_scheduler"
cloudwatch_event_rule_cron_expression = "cron(0 0 1 * ? *)"

# ------------------------------
# SES MODULE
# ------------------------------
email_addresses = [
  "Email1@domain.com",
  "Email2@domain.com"
]

# ------------------------------
# ACM MODULE
# ------------------------------
domain      = "yourdomain.com"      # Replace with real domain
environment = "prod"

# ------------------------------
# CLOUDWATCH ALARMS MODULE
# ------------------------------
ec2_instance_id = "i-0123456789abcdef0"          # Replace with real EC2 ID
rds_instance_id = "rds-instance-12345678"        # Replace with real RDS ID
sns_topic_arn   = "arn:aws:sns:us-east-1:123456789012:MySNSTopic"

# ------------------------------
# IAM PASSWORD POLICY MODULE
# ------------------------------
minimum_password_length       = 14
require_symbols               = true
require_numbers               = true
require_uppercase_characters = true
require_lowercase_characters = true
allow_users_to_change_password = true
max_password_age              = 90
password_reuse_prevention     = 5
hard_expiry                   = false
