# Enable default encryption for all new EBS volumes using AWS-managed keys (or override with KMS)
resource "aws_ebs_encryption_by_default" "default" {
  enabled = true # Ensures all new EBS volumes are encrypted by default
}

# Create a custom KMS key for EC2 EBS volume encryption
resource "aws_kms_key" "ebs_kms" {
  description         = "Customer-managed KMS key for EBS volume encryption"
  enable_key_rotation = true # Enables annual key rotation for compliance
}

# Create a custom KMS key for RDS encryption
resource "aws_kms_key" "rds_kms" {
  description         = "Customer-managed KMS key for RDS encryption"
  enable_key_rotation = true # Enables annual key rotation
}

# Provision an RDS MySQL instance with encryption enabled using KMS
resource "aws_db_instance" "example" {
  identifier          = "mydb"                     # Unique name for RDS instance
  engine              = "mysql"                    # Engine type
  instance_class      = "db.t3.micro"              # Free-tier eligible instance class
  allocated_storage   = 20                         # Storage in GB
  storage_encrypted   = true                       # Enable encryption at rest
  kms_key_id          = aws_kms_key.rds_kms.arn    # Use custom KMS key for encryption

  skip_final_snapshot = true                       # For test/demo; in prod, set to false
}
