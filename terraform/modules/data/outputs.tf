output "rds_endpoint" {
  description = "Endpoint RDS (hôte:port)"
  value       = aws_db_instance.this.endpoint
}

output "rds_address" {
  description = "Nom d'hôte RDS (sans le port), utilisé par Ansible"
  value       = aws_db_instance.this.address
}

output "rds_port" {
  description = "Port RDS"
  value       = aws_db_instance.this.port
}

output "db_name" {
  description = "Nom de la base applicative"
  value       = aws_db_instance.this.db_name
}

output "db_username" {
  description = "Utilisateur maître de la base"
  value       = aws_db_instance.this.username
}

output "db_password" {
  description = "Mot de passe maître généré (sensible : terraform output -raw db_password)"
  value       = random_password.db.result
  sensitive   = true
}

output "bucket_name" {
  description = "Nom du bucket S3"
  value       = aws_s3_bucket.this.bucket
}

output "bucket_arn" {
  description = "ARN du bucket S3"
  value       = aws_s3_bucket.this.arn
}
