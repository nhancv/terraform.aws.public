output "lb_id_frontend" {
  value = aws_lb.frontend.id
}

output "lb_tg_arn_frontend" {
  value = aws_lb_target_group.frontend.arn
}

output "lb_dns_frontend" {
  value = aws_lb.frontend.dns_name
}

output "lb_id_backend" {
  value = aws_lb.backend.id
}

output "lb_tg_arn_backend" {
  value = aws_lb_target_group.backend.arn
}

output "lb_dns_backend" {
  value = aws_lb.backend.dns_name
}

output "lb_id_database" {
  value = aws_lb.database.id
}

output "lb_tg_arn_database" {
  value = aws_lb_target_group.database.arn
}

output "lb_dns_database" {
  value = aws_lb.database.dns_name
}