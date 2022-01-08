output "asg_bastion" {
  value = aws_autoscaling_group.bastion
}

output "asg_frontend" {
  value = aws_autoscaling_group.frontend
}

output "asg_backend" {
  value = aws_autoscaling_group.backend
}

output "asg_database" {
  value = aws_autoscaling_group.database
}