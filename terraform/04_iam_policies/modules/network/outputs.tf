output "vpc_id" {
  description = "The VPCs ID"
  value       = aws_vpc.main.id
}

output "public_subnet_id" {
  description = "The public Subnet ID"
  value       = aws_subnet.public.id
}

output "private_subnet_id" {
  description = "The private Subnet ID"
  value       = aws_subnet.private.id
}