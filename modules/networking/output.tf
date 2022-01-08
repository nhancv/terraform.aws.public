output "vpc_id" {
  value = aws_vpc.project.id
}

output "subnet_public" {
  value = aws_subnet.public[*].id
}

output "subnet_frontend" {
  value = aws_subnet.frontend[*].id
}

output "subnet_backend" {
  value = aws_subnet.backend[*].id
}

output "subnet_database" {
  value = aws_subnet.database[*].id
}

output "sg_bastion" {
  value = aws_security_group.bastion.id
}

output "sg_http" {
  value = aws_security_group.http.id
}

output "sg_private" {
  value = aws_security_group.private.id
}
