resource "aws_iam_account_password_policy" "this" {
  minimum_password_length          = var.minimum_password_length          # Enforce strong minimum length
  require_symbols                  = var.require_symbols                  # Require special characters
  require_numbers                  = var.require_numbers                  # Require at least one number
  require_uppercase_characters    = var.require_uppercase_characters     # Enforce uppercase
  require_lowercase_characters    = var.require_lowercase_characters     # Enforce lowercase
  allow_users_to_change_password  = var.allow_users_to_change_password   # Allow password self-management
  max_password_age                = var.max_password_age                 # Enforce password rotation
  password_reuse_prevention       = var.password_reuse_prevention        # Prevent reuse of recent passwords
  hard_expiry                     = var.hard_expiry                      # Force change after expiry (false = soft expiry)
}
