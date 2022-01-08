# This alb places at public subnet and forward traffic internet to frontend subnet
resource "aws_lb" "frontend" {
  name               = "${var.env}-${var.project}-lb-frontend"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.sg_http]
  subnets            = tolist(var.subnet_public)
}
resource "aws_lb_target_group" "frontend" {
  name     = "${var.env}-${var.project}-lb-tg-frontend"
  vpc_id   = var.vpc_id
  protocol = var.lb_tg_protocol
  port     = var.lb_tg_port
  lifecycle {
    create_before_destroy = true
    ignore_changes        = [name]
  }
}
resource "aws_lb_listener" "frontend" {
  load_balancer_arn = aws_lb.frontend.arn
  port              = var.lb_listener_port
  protocol          = var.lb_listener_protocol
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend.arn
  }
}

# This alb places at frontend subnet and forward traffic internally to backend subnet
resource "aws_lb" "backend" {
  name               = "${var.env}-${var.project}-lb-backend"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [var.sg_http]
  subnets            = tolist(var.subnet_frontend)
}
resource "aws_lb_target_group" "backend" {
  name     = "${var.env}-${var.project}-lb-tg-backend"
  vpc_id   = var.vpc_id
  protocol = var.lb_tg_protocol
  port     = var.lb_tg_port
  lifecycle {
    create_before_destroy = true
    ignore_changes        = [name]
  }
}
resource "aws_lb_listener" "backend" {
  load_balancer_arn = aws_lb.backend.arn
  port              = var.lb_listener_port
  protocol          = var.lb_listener_protocol
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend.arn
  }
}

# This alb places at backend subnet and forward traffic internally to database subnet
resource "aws_lb" "database" {
  name               = "${var.env}-${var.project}-lb-database"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [var.sg_http]
  subnets            = tolist(var.subnet_backend)
}
resource "aws_lb_target_group" "database" {
  name     = "${var.env}-${var.project}-lb-tg-database"
  vpc_id   = var.vpc_id
  protocol = var.lb_tg_protocol
  port     = var.lb_tg_port
  lifecycle {
    create_before_destroy = true
    ignore_changes        = [name]
  }
}
resource "aws_lb_listener" "database" {
  load_balancer_arn = aws_lb.database.arn
  port              = var.lb_listener_port
  protocol          = var.lb_listener_protocol
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.database.arn
  }
}
