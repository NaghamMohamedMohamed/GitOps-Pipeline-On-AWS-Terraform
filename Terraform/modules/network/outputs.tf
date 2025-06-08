output "vpc_id" {
  value = aws_vpc.main.id
}

output "aws_nat_gateway_id" {
  value = aws_nat_gateway.nat.public_ip
  
}

output "public_subnet_ids_list" {
  value = [for subnet in aws_subnet.public : subnet.id]
}

output "private_subnet_ids_list" {
  value = [for subnet in aws_subnet.private : subnet.id]
}