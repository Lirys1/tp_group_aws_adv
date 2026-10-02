output "vpc_id" {
  description = "ID du VPC"
  value       = aws_vpc.this.id
}

output "public_subnet_ids" {
  description = "IDs des sous-réseaux publics (ALB, bastion)"
  value       = aws_subnet.public[*].id
}

output "app_subnet_ids" {
  description = "IDs des sous-réseaux applicatifs privés (ASG)"
  value       = aws_subnet.app[*].id
}

output "data_subnet_ids" {
  description = "IDs des sous-réseaux de données privés (RDS)"
  value       = aws_subnet.data[*].id
}

output "alb_security_group_id" {
  description = "Security group de l'ALB"
  value       = aws_security_group.alb.id
}

output "bastion_security_group_id" {
  description = "Security group du bastion"
  value       = aws_security_group.bastion.id
}

output "app_security_group_id" {
  description = "Security group des instances app"
  value       = aws_security_group.app.id
}

output "rds_security_group_id" {
  description = "Security group de la base RDS"
  value       = aws_security_group.rds.id
}

output "nat_gateway_public_ip" {
  description = "IP publique de sortie des instances privées (null si NAT désactivée)"
  value       = var.enable_nat_gateway ? aws_eip.nat[0].public_ip : null
}
