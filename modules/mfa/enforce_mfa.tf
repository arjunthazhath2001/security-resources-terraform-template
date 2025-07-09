# ───────────────────────────────────────────────────────────────
# STEP 8: Define a policy document to enforce MFA usage
# This denies *all actions* unless MFA is present, except for a
# few specific actions needed to set up/enable MFA.
# Applied to users/groups via an IAM policy.
# ───────────────────────────────────────────────────────────────
data "aws_iam_policy_document" "enforce_mfa" {
  statement {
    sid    = "DenyAllExceptListedIfNoMFA"  # Statement ID for clarity
    effect = "Deny"

    # Allow only certain actions when MFA is *not* present
    not_actions = [
      "iam:CreateVirtualMFADevice",
      "iam:EnableMFADevice",
      "iam:GetUser",
      "iam:ListMFADevices",
      "iam:ListVirtualMFADevices",
      "iam:ResyncMFADevice",
      "sts:GetSessionToken"
    ]

    # Deny everything else when MFA is not used
    resources = ["*"]

    # Only applies the Deny if MFA is not enabled
    condition {
      test     = "BoolIfExists"
      variable = "aws:MultiFactorAuthPresent"
      values   = ["false"]
    }
  }
}

# ───────────────────────────────────────────────────────────────
# STEP 9: Create the IAM policy using the document above
# This policy enforces MFA on users/groups it’s attached to.
# Should be attached to IAM users or groups to enforce security.
# ───────────────────────────────────────────────────────────────
resource "aws_iam_policy" "enforce_mfa" {
  name        = "enforce-to-use-mfa"
  path        = "/"
  description = "Policy that denies all actions if MFA is not enabled"
  policy      = data.aws_iam_policy_document.enforce_mfa.json
}
