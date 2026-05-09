output "vpc_id" {
  value = aws_vpc.main.id
}

output "vpc_cidr" {
  value = aws_vpc.main.cidr_block
}

output "public_subnet_id" {
  value = aws_subnet.public_1a.id
}

output "public_subnet_cidr" {
  value = aws_subnet.public_1a.cidr_block
}

output "private_subnet_id" {
  value = aws_subnet.private_1a.id
}

output "private_subnet_cidr" {
  value = aws_subnet.private_1a.cidr_block
}

output "nat_gateway_id" {
  value = aws_nat_gateway.main.id
}

output "igw_id" {
  value = aws_internet_gateway.main.id
}