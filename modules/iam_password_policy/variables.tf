# Enforce strong password policy with a minimum length
variable "minimum_password_length" {
  type    = number
  default = 14
}

# Require at least one special character
variable "require_symbols" {
  type    = bool
  default = true
}

# Require at least one numeric character
variable "require_numbers" {
  type    = bool
  default = true
}

# Require at least one uppercase letter
variable "require_uppercase_characters" {
  type    = bool
  default = true
}

# Require at least one lowercase letter
variable "require_lowercase_characters" {
  type    = bool
  default = true
}

# Allow users to manage their own passwords
variable "allow_users_to_change_password" {
  type    = bool
  default = true
}

# Rotate password every 90 days
variable "max_password_age" {
  type    = number
  default = 90
}

# Disallow reusing the last 5 passwords
variable "password_reuse_prevention" {
  type    = number
  default = 5
}

# Control whether password expiry blocks login
variable "hard_expiry" {
  type    = bool
  default = false
}
