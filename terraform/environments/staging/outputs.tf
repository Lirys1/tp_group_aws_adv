output "environment" {
  description = "Environnement déployé"
  value       = var.environment
}

output "alb_url" {
  description = "URL publique de l'application"
  value       = "http://${module.compute.alb_dns_name}"
}

output "asg_name" {
  description = "Nom de l'Auto Scaling Group"
  value       = module.compute.asg_name
}

output "bastion_public_ip" {
  description = "IP publique du bastion (ProxyJump Ansible)"
  value       = module.compute.bastion_public_ip
}

output "rds_address" {
  description = "Hôte RDS"
  value       = module.data.rds_address
}

output "db_name" {
  description = "Nom de la base"
  value       = module.data.db_name
}

output "db_username" {
  description = "Utilisateur maître RDS"
  value       = module.data.db_username
}

output "db_password" {
  description = "Mot de passe RDS (terraform output -raw db_password)"
  value       = module.data.db_password
  sensitive   = true
}

output "bucket_name" {
  description = "Bucket S3 de l'environnement"
  value       = module.data.bucket_name
}
