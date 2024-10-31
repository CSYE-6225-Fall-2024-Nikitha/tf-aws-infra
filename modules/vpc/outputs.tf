output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_ids" {
  value = aws_subnet.public_subnet.*.id
}

output "private_subnet_ids" {
  value = aws_subnet.private_subnet.*.id
}

output "internet_gateway_id" {
  value = aws_internet_gateway.main.id
}

output "ec2_public_dns" {
  value = aws_instance.app_instance.public_dns
}

output "db_name" {
  value = aws_db_instance.rds_instance.db_name
}

output "db_user" {
  value = aws_db_instance.rds_instance.username
}

output "db_password" {
  value = aws_db_instance.rds_instance.password
}

output "db_host" {
  value = aws_db_instance.rds_instance.address
}

output "db_port" {
  value = aws_db_instance.rds_instance.port
}

variable "ami" {
  description = "The ami id"
  type        = string
}