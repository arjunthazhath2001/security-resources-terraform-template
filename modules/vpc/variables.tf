# ------------------------------
# VPC MODULE INPUT VARIABLES
# ------------------------------

# CIDR block for the VPC (e.g., "10.0.0.0/16")
# Defines the IP range for the entire VPC.
variable "cidr" {
  description = "CIDR block for the VPC (e.g., 10.0.0.0/16)"
  default     = ""
}

# CIDR block for the public subnet (e.g., "10.0.1.0/24")
# Resources in this subnet can be accessed publicly if a route to IGW is present.
variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet (e.g., 10.0.1.0/24)"
  default     = ""
}

# CIDR block for the private subnet (e.g., "10.0.2.0/24")
# Resources in this subnet are private and typically access the internet via NAT.
variable "private_subnet_cidr" {
  description = "CIDR block for the private subnet (e.g., 10.0.2.0/24)"
  default     = ""
}
