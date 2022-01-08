variable "env" {}
variable "project" {}

# Subnet
variable "subnet_public" {}
variable "subnet_frontend" {}
variable "subnet_backend" {}
variable "subnet_database" {}

# Security group
variable "sg_bastion" {}
variable "sg_http" {}
variable "sg_private" {}

# Elastic load balancing
variable "lb_tg_arn_frontend" {}
variable "lb_tg_arn_backend" {}
variable "lb_tg_arn_database" {}

# Instance key pair
variable "key_id_bastion" {}
variable "key_id_project" {}

# Instance type
variable "instance_type_bastion" {
  type    = string
  default = "t2.micro"
}

variable "instance_type_frontend" {
  type    = string
  default = "t2.micro"
}

variable "instance_type_backend" {
  type    = string
  default = "t2.micro"
}

variable "instance_type_database" {
  type    = string
  default = "t2.micro"
}
