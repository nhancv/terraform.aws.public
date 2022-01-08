/**
TERRAFORM, INFRASTRUCTURE AS CODE

RESOURCE naming template:
{env}-{project}-{res}-{module}
WHERE
env: [draft,dev,stag,prod]
EX:
dev-project1-key-bastion
======================================================
DEPLOY
terraform init
terraform plan
terraform apply [-auto-approve]

VIEW STATE
terraform show
-> Read instance input, public_ip

DESTROY
terraform plan -destroy
terraform apply -destroy [-auto-approve]

**/

terraform {
  # Specifies Terraform Cloud to store our state file
  cloud {
    organization = "Lab000"

    workspaces {
      name = "project-com-aws-draft"
    }
  }

  # Defines AWS providers
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }
  required_version = ">= 0.14.9"
}

provider "aws" {
  region     = var.AWS_REGION
  access_key = var.AWS_ACCESS_KEY
  secret_key = var.AWS_SECRET_KEY
}

module "networking" {
  env                = var.env
  project            = var.project
  source             = "./modules/networking"
  cidr_vpc           = "10.0.0.0/16"
  availability_zones = ["us-east-1a", "us-east-1b"]
  cidrs_public       = ["10.0.1.0/24", "10.0.2.0/24"]
  cidrs_frontend     = ["10.0.3.0/24", "10.0.4.0/24"]
  cidrs_backend      = ["10.0.5.0/24", "10.0.6.0/24"]
  cidrs_database     = ["10.0.7.0/24", "10.0.8.0/24"]
  access_ip          = "0.0.0.0/0"
}

# Sends your public key to the instance
# KEY_NAME=draft-project1-key-bastion && ssh-keygen -t rsa -f key_pairs/$KEY_NAME -C "KEY_NAME"
# ssh -i key_pairs/draft-project1-key-bastion ubuntu@[bastion_public_ip]
# Default username of ubuntu is ubuntu. AWS Linux is ec2-user

resource "aws_key_pair" "bastion" {
  key_name   = "${var.env}-${var.project}-key-bastion"
  public_key = try(var.public_key_pair_bastion, file("key_pairs/${var.env}-${var.project}-key-bastion.pub"))
}
resource "aws_key_pair" "project" {
  key_name   = "${var.env}-${var.project}-key-private"
  public_key = try(var.public_key_pair_project, file("key_pairs/${var.env}-${var.project}-key-private.pub"))
}

module "loadbalancing" {
  env             = var.env
  project         = var.project
  source          = "./modules/loadbalancing"
  vpc_id          = module.networking.vpc_id
  subnet_public   = module.networking.subnet_public
  subnet_frontend = module.networking.subnet_frontend
  subnet_backend  = module.networking.subnet_backend
  subnet_database = module.networking.subnet_database
  sg_bastion      = module.networking.sg_bastion
  sg_http         = module.networking.sg_http
  sg_private      = module.networking.sg_private
}

module "compute" {
  env                = var.env
  project            = var.project
  source             = "./modules/compute"
  subnet_public      = module.networking.subnet_public
  subnet_frontend    = module.networking.subnet_frontend
  subnet_backend     = module.networking.subnet_backend
  subnet_database    = module.networking.subnet_database
  sg_bastion         = module.networking.sg_bastion
  sg_http            = module.networking.sg_http
  sg_private         = module.networking.sg_private
  lb_tg_arn_frontend = module.loadbalancing.lb_tg_arn_frontend
  lb_tg_arn_backend  = module.loadbalancing.lb_tg_arn_backend
  lb_tg_arn_database = module.loadbalancing.lb_tg_arn_database
  key_id_bastion     = aws_key_pair.bastion.id
  key_id_project     = aws_key_pair.project.id

  depends_on = [module.loadbalancing]
}
