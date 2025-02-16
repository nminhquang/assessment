# Output the VPC and subnet IDs
output "vpc_id" {
  value = aws_vpc.main.id
}

output "frontend_subnet_ids" {
  value = aws_subnet.frontend[*].id
}

output "application_subnet_ids" {
  value = aws_subnet.application[*].id
}

output "database_subnet_ids" {
  value = aws_subnet.database[*].id
}