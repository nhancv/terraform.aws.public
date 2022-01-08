variable "env" {
  default = "env"
}

variable "project" {
  default = "project"
}

variable "AWS_REGION" {
  default = "us-east-1"
}

variable "AWS_ACCESS_KEY" {
  sensitive = true
  default = ""
}

variable "AWS_SECRET_KEY" {
  sensitive = true
  default = ""
}

variable "public_key_pair_bastion" {
  sensitive = true
}

variable "public_key_pair_project" {
  sensitive = true
}
