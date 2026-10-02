# Déclarations identiques entre staging/ et prod/ : les VALEURS sont dans
# terraform.tfvars (versionné, sans secret).

variable "region" {
  description = "Région AWS de déploiement"
  type        = string
  default     = "eu-west-3"
}

variable "project" {
  description = "Nom court du projet (minuscules), préfixe de toutes les ressources"
  type        = string
  default     = "neocargo"
}

variable "environment" {
  description = "Nom de l'environnement"
  type        = string

  validation {
    condition     = contains(["staging", "prod"], var.environment)
    error_message = "environment doit valoir staging ou prod."
  }
}

# --- Réseau ------------------------------------------------------------

variable "vpc_cidr" {
  description = "CIDR du VPC"
  type        = string
}

variable "public_subnet_cidrs" {
  description = "CIDR des sous-réseaux publics"
  type        = list(string)
}

variable "app_subnet_cidrs" {
  description = "CIDR des sous-réseaux applicatifs"
  type        = list(string)
}

variable "data_subnet_cidrs" {
  description = "CIDR des sous-réseaux de données"
  type        = list(string)
}

variable "enable_nat_gateway" {
  description = "Crée une NAT Gateway pour les instances privées"
  type        = bool
  default     = true
}

variable "bastion_allowed_cidrs" {
  description = "CIDR autorisés en SSH sur le bastion (idéalement votre IP publique en /32)"
  type        = list(string)
}

# --- Compute -----------------------------------------------------------

variable "instance_type" {
  description = "Type d'instance des serveurs app"
  type        = string
}

variable "key_name" {
  description = "Nom de la paire de clés EC2 existante dans le compte de la personne qui applique"
  type        = string
}

variable "instance_profile_name" {
  description = "Profil IAM existant (ex : LabInstanceProfile si présent dans le Learner Lab). null = aucun. Jamais créé par Terraform"
  type        = string
  default     = null
}

variable "asg_min_size" {
  description = "Taille minimale de l'ASG"
  type        = number
}

variable "asg_max_size" {
  description = "Taille maximale de l'ASG"
  type        = number
}

variable "asg_desired_capacity" {
  description = "Capacité souhaitée de l'ASG"
  type        = number
}

variable "enable_bastion" {
  description = "Crée le bastion SSH (nécessaire pour Ansible)"
  type        = bool
  default     = true
}

# --- Données -----------------------------------------------------------

variable "db_instance_class" {
  description = "Classe d'instance RDS"
  type        = string
}

variable "db_name" {
  description = "Nom de la base applicative"
  type        = string
  default     = "trackfleet"
}

variable "db_backup_retention_days" {
  description = "Rétention des sauvegardes RDS (jours)"
  type        = number
  default     = 0
}

variable "bucket_force_destroy" {
  description = "Autorise destroy à vider le bucket S3"
  type        = bool
  default     = false
}
