variable "env" {}
variable "project" {}

variable "vpc_id" {}
variable "subnet_public" {}
variable "subnet_frontend" {}
variable "subnet_backend" {}
variable "subnet_database" {}
variable "sg_bastion" {}
variable "sg_http" {}
variable "sg_private" {}

variable "lb_tg_protocol" {
  default = "HTTP"
}

variable "lb_tg_port" {
  default = 80
}

variable "lb_listener_protocol" {
  default = "HTTP"
}

variable "lb_listener_port" {
  default = 80
}