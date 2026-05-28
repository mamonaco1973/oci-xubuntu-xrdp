# ==============================================================================
# Roles / IAM
# ------------------------------------------------------------------------------
# OCI does not use IAM instance profiles for credential injection.
# Passwords are passed directly via templatefile at apply time and stored
# as sensitive outputs in terraform.tfstate (retrieved with get_password.sh).
# ==============================================================================
