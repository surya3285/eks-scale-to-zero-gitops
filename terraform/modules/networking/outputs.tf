output "vpc_id" {
  description = "ID of the VPC."
  value       = aws_vpc.this.id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC."
  value       = aws_vpc.this.cidr_block
}

output "public_subnet_ids" {
  description = "IDs of the public subnets, keyed by AZ."
  value       = { for az, s in aws_subnet.public : az => s.id }
}

output "private_subnet_ids" {
  description = "IDs of the private subnets, keyed by AZ."
  value       = { for az, s in aws_subnet.private : az => s.id }
}

output "private_subnet_ids_list" {
  description = "IDs of the private subnets as a flat list, convenient for EKS module inputs."
  value       = [for s in aws_subnet.private : s.id]
}

output "nat_gateway_ids" {
  description = "IDs of the NAT gateway(s) created."
  value       = { for az, n in aws_nat_gateway.this : az => n.id }
}
