provider "aws" {
  region = var.region
}

module "vpc" {
  source              = "./modules/vpc"
  cidr                = var.vpc_cidr
  public_subnet_cidr  = var.vpc_public_subnet_cidr
  private_subnet_cidr = var.vpc_private_subnet_cidr
}

module "access_key_rotater_function" {
  source               = "./modules/lambda"
  max_key_age          = var.max_access_key_age
  expire_key_age       = var.delete_key_age
  function_name        = var.lambda_function_name
  function_role_name   = var.iam_lambda_role_name
  admin_username       = var.account_admin_username
  admin_email          = var.account_admin_email
  admin_group_name     = var.admin_group
  tag_key              = var.user_skip_tag_key
  tag_value            = var.user_skip_tag_value
  vpc_id               = var.existing_vpc ? var.vpc_id : module.vpc.vpc_id
  subnet_id            = var.existing_vpc ? var.subnet_id : module.vpc.subnet_id
  vpc_cidr             = var.existing_vpc ? var.existing_vpc_cidr : var.vpc_cidr
  security_group       = var.security_group
}

module "scheduler" {
  source          = "./modules/scheduler"
  scheduler_name  = var.cloudwatch_event_rule_name
  cron_expression = var.cloudwatch_event_rule_cron_expression
  lambda_arn      = module.access_key_rotater_function.access_key_rotater_function_arn
  function_name   = var.lambda_function_name
}

module "email_scheduler" {
  source = "./modules/ses"
  mails  = var.email_addresses
}

module "acm" {
  source      = "./modules/acm"
  domain      = var.domain
  environment = var.environment
}

module "cloud_trail" {
  source = "./modules/cloud_trail"
}

module "mfa" {
  source = "./modules/mfa"
}

module "cloudwatch_alarms" {
  source          = "./modules/cloudwatch_alarms"
  ec2_instance_id = var.ec2_instance_id
  rds_instance_id = var.rds_instance_id
  sns_topic_arn   = var.sns_topic_arn
}

module "encryption" {
  source = "./modules/encryption"
  # Add any encryption-related vars here if needed
}

module "iam_password_policy" {
  source                        = "./modules/iam_password_policy"
  minimum_password_length       = var.minimum_password_length
  require_symbols               = var.require_symbols
  require_numbers               = var.require_numbers
  require_uppercase_characters = var.require_uppercase_characters
  require_lowercase_characters = var.require_lowercase_characters
  allow_users_to_change_password = var.allow_users_to_change_password
  max_password_age              = var.max_password_age
  password_reuse_prevention     = var.password_reuse_prevention
  hard_expiry                   = var.hard_expiry
}
