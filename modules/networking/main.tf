resource "aws_vpc" "project" {
  cidr_block           = var.cidr_vpc
  enable_dns_hostnames = true
  enable_dns_support   = true
  instance_tenancy     = "default"
  tags                 = {
    Name = "${var.env}-${var.project}-vpc"
  }
}

resource "aws_subnet" "public" {
  count                   = length(var.cidrs_public)
  vpc_id                  = aws_vpc.project.id
  cidr_block              = var.cidrs_public[count.index]
  map_public_ip_on_launch = true
  availability_zone       = var.availability_zones[count.index]
  tags                    = {
    Name = "${var.env}-${var.project}-public-${count.index + 1}"
  }
}

resource "aws_subnet" "frontend" {
  count             = length(var.cidrs_frontend)
  vpc_id            = aws_vpc.project.id
  cidr_block        = var.cidrs_frontend[count.index]
  availability_zone = var.availability_zones[count.index]
  tags              = {
    Name = "${var.env}-${var.project}-frontend-${count.index + 1}"
  }
}

resource "aws_subnet" "backend" {
  count             = length(var.cidrs_backend)
  vpc_id            = aws_vpc.project.id
  cidr_block        = var.cidrs_backend[count.index]
  availability_zone = var.availability_zones[count.index]
  tags              = {
    Name = "${var.env}-${var.project}-backend-${count.index + 1}"
  }
}

resource "aws_subnet" "database" {
  count             = length(var.cidrs_database)
  vpc_id            = aws_vpc.project.id
  cidr_block        = var.cidrs_database[count.index]
  availability_zone = var.availability_zones[count.index % 2]
  tags              = {
    Name = "${var.env}-${var.project}-database-${count.index + 1}"
  }
}

resource "aws_internet_gateway" "project" {
  vpc_id = aws_vpc.project.id
  tags   = {
    Name = "${var.env}-${var.project}-igw"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_eip" "project" {

}

resource "aws_nat_gateway" "project" {
  allocation_id = aws_eip.project.id
  subnet_id     = aws_subnet.public[1].id
  tags          = {
    Name = "${var.env}-${var.project}-natgw"
  }

  depends_on = [aws_internet_gateway.project]
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.project.id

  tags = {
    Name = "${var.env}-${var.project}-rt-public"
  }
}

resource "aws_route_table" "project" {
  vpc_id = aws_vpc.project.id

  tags = {
    Name = "${var.env}-${var.project}-rt-private"
  }
}

resource "aws_route" "default_public" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.project.id
}

resource "aws_route" "default_private" {
  route_table_id         = aws_route_table.project.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.project.id
}

resource "aws_default_route_table" "project" {
  default_route_table_id = aws_vpc.project.default_route_table_id

  tags = {
    Name = "${var.env}-${var.project}-rt-default"
  }
}

resource "aws_route_table_association" "public" {
  count          = length(var.cidrs_public)
  subnet_id      = aws_subnet.public.*.id[count.index]
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "frontend" {
  count          = length(var.cidrs_frontend)
  subnet_id      = aws_subnet.frontend.*.id[count.index]
  route_table_id = aws_route_table.project.id
}

resource "aws_route_table_association" "backend" {
  count          = length(var.cidrs_backend)
  subnet_id      = aws_subnet.backend.*.id[count.index]
  route_table_id = aws_route_table.project.id
}

resource "aws_route_table_association" "database" {
  count          = length(var.cidrs_database)
  subnet_id      = aws_subnet.database.*.id[count.index]
  route_table_id = aws_route_table.project.id
}

resource "aws_security_group" "bastion" {
  name        = "${var.env}-${var.project}-sg-bastion"
  description = "Allow SSH inbound traffic"
  vpc_id      = aws_vpc.project.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.access_ip]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "http" {
  name        = "${var.env}-${var.project}-sg-http"
  description = "Allow all inbound HTTP traffic"
  vpc_id      = aws_vpc.project.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "private" {
  name        = "${var.env}-${var.project}-sg-private"
  description = "Allow SSH inbound traffic from Bastion Host and HTTP"
  vpc_id      = aws_vpc.project.id

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.http.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
