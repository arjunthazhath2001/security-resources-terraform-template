# ───────────────────────────────────────────────────────────────
# IAM ADMINISTRATOR SETUP: User, Group, Policies, and MFA Enforcement
# This creates an admin IAM group and user, attaches full access,
# and enforces MFA policy for security best practices.
# ───────────────────────────────────────────────────────────────

# ───────────────────────────────────────────────────────────────
# STEP 1: Create an IAM group for administrators
# ───────────────────────────────────────────────────────────────
resource "aws_iam_group" "administrators" {
  name = "Administrators"
  path = "/" # Root-level path
}

# ───────────────────────────────────────────────────────────────
# STEP 2: Fetch the pre-defined AWS AdministratorAccess policy
# This is a managed policy by AWS that grants full admin rights
# ───────────────────────────────────────────────────────────────
data "aws_iam_policy" "administrator_access" {
  name = "AdministratorAccess"
}

# ───────────────────────────────────────────────────────────────
# STEP 3: Attach the AdministratorAccess policy to the admin group
# ───────────────────────────────────────────────────────────────
resource "aws_iam_group_policy_attachment" "administrators" {
  group      = aws_iam_group.administrators.name
  policy_arn = data.aws_iam_policy.administrator_access.arn
}

# ───────────────────────────────────────────────────────────────
# STEP 4: Create an IAM user to act as an administrator
# ───────────────────────────────────────────────────────────────
resource "aws_iam_user" "administrator" {
  name = "Administrator"
}

# ───────────────────────────────────────────────────────────────
# STEP 5: Add the IAM user to the Administrators group
# ───────────────────────────────────────────────────────────────
resource "aws_iam_user_group_membership" "devstream" {
  user   = aws_iam_user.administrator.name
  groups = [aws_iam_group.administrators.name]
}

# ───────────────────────────────────────────────────────────────
# STEP 6: Create a login profile (console access) for the user
# - Triggers password reset on first login
# - Automatically generates a temporary password
# ───────────────────────────────────────────────────────────────
resource "aws_iam_user_login_profile" "administrator" {
  user                    = aws_iam_user.administrator.name
  password_reset_required = true
}

# ───────────────────────────────────────────────────────────────
# STEP 7: Attach a custom MFA enforcement policy to the group
# Ensures users in the group must use MFA for sensitive actions
# (Check enforce_mfa.tf for the policy document)
# ───────────────────────────────────────────────────────────────
resource "aws_iam_group_policy_attachment" "enforce_mfa" {
  group      = aws_iam_group.administrators.name
  policy_arn = aws_iam_policy.enforce_mfa.arn
}

# ───────────────────────────────────────────────────────────────
# OUTPUT: Temporary console login password for administrator user
# Marked as sensitive to avoid showing in plan/apply output
# ───────────────────────────────────────────────────────────────
output "password" {
  value     = aws_iam_user_login_profile.administrator.password
  sensitive = true
}
