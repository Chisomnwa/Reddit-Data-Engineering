resource "random_password" "redshift_pass" {
  length  = 10
  min_lower = 5
  min_numeric = 2
  min_special = 1
  min_upper = 2
}

resource "random_password" "redshift_username" {
  length  = 9
  min_lower = 6
  min_numeric = 2
  upper = false
  special = false # Just to be explicit that no special chars are used
}

resource "aws_ssm_parameter" "ssm_password" {
  name  = var.password
  type  = "String"
  value = random_password.redshift_pass.result
}

resource "aws_ssm_parameter" "ssm_username" {
  name  = var.username
  type  = "String"
  value = "a${random_password.redshift_username.result}" 
}

# Look for arguments that can change and parameterize those arguments