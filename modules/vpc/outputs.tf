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

output "sns_topic_arn" {
  description = "ARN of the SNS topic"
  value       = aws_sns_topic.user_verifications.arn
}

output "lambda_function_arn" {
  description = "ARN of the Lambda function"
  value       = aws_lambda_function.email_verification_function.arn
}