variable "prefix" {
  description = "Prefix used to compose the resouces names"
  type        = string
}

variable "instance_type" {
  description = "Server instance type"
  type        = string
}

variable "user_data_template" {
  description = "User Data template to use for provisioning Pritunl server"
  type        = string
}

variable "ssh_user" {
  description = "Default SSH user for this AMI. e.g. `ec2-user` for Amazon Linux and `ubuntu` for Ubuntu systems"
  type        = string
}

variable "user_data" {
  description = "User data content. Will be ignored if `user_data_base64` is set"
  type        = list(string)
  default     = []
}
