variable "domain" {
  description = "The domain name for which the ACM certificate is requested"
  type        = string
  default     = ""
}

variable "environment" {
  description = "The environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"
}
