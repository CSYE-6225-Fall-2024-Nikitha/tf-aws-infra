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