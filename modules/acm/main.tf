resource "aws_acm_certificate" "ssl_cert" {
  domain_name       = var.domain              # Domain to request the certificate for
  validation_method = "DNS"                   # DNS validation is preferred for automation

  # Optional: Add tags for resource tracking and governance
  tags = {
    Name        = "ACM Certificate for ${var.domain}"
    Environment = var.environment
  }
}
