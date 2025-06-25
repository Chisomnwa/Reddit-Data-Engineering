variable "password" {
  description = "This is the name of the SSM parameter"
  default = "redshift_password"
}

variable "username" {
  description = "This is the value the SSM parameter"
  default = "redshift_username"
}
