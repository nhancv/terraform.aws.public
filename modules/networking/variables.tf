variable "env" {}
variable "project" {}

variable "cidr_vpc" {
  type = string
}

variable "availability_zones" {
  type = list(string)
}

variable "cidrs_public" {
  type = list(any)
}

variable "cidrs_frontend" {
  type = list(any)
}

variable "cidrs_backend" {
  type = list(any)
}

variable "cidrs_database" {
  type = list(any)
}

variable "access_ip" {
  type = string
}
