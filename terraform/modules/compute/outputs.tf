output "alb_dns_name" {
  description = "Nom DNS public de l'ALB"
  value       = aws_lb.this.dns_name
}

output "alb_arn" {
  description = "ARN de l'ALB"
  value       = aws_lb.this.arn
}

output "target_group_arn" {
  description = "ARN du Target Group"
  value       = aws_lb_target_group.app.arn
}

output "asg_name" {
  description = "Nom de l'Auto Scaling Group"
  value       = aws_autoscaling_group.app.name
}

output "launch_template_id" {
  description = "ID du Launch Template"
  value       = aws_launch_template.app.id
}

output "bastion_public_ip" {
  description = "IP publique du bastion (null si désactivé)"
  value       = var.enable_bastion ? aws_instance.bastion[0].public_ip : null
}

output "ami_id" {
  description = "AMI utilisée pour les instances"
  value       = data.aws_ami.ubuntu.id
}
