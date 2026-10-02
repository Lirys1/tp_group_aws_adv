variable "name_prefix" {
  description = "Préfixe de nommage des ressources (ex : neocargo-staging). 21 caractères max (limite de 32 caractères des noms ALB/TG)"
  type        = string

  validation {
    condition     = length(var.name_prefix) <= 21
    error_message = "name_prefix doit faire 21 caractères au plus (le nom de l'ALB est limité à 32)."
  }
}

# --- Entrées venant du module network --------------------------------

variable "vpc_id" {
  description = "ID du VPC (output du module network)"
  type        = string
}

variable "public_subnet_ids" {
  description = "Sous-réseaux publics pour l'ALB et le bastion"
  type        = list(string)
}

variable "app_subnet_ids" {
  description = "Sous-réseaux privés pour les instances de l'ASG"
  type        = list(string)
}

variable "alb_security_group_id" {
  description = "Security group de l'ALB"
  type        = string
}

variable "app_security_group_id" {
  description = "Security group des instances app"
  type        = string
}

variable "bastion_security_group_id" {
  description = "Security group du bastion"
  type        = string
}

# --- Instances ---------------------------------------------------------

variable "instance_type" {
  description = "Type d'instance EC2 des serveurs app"
  type        = string
}

variable "ami_owner" {
  description = "Propriétaire de l'AMI (099720109477 = Canonical)"
  type        = string
  default     = "099720109477"
}

variable "ami_name_filter" {
  description = "Filtre de nom de l'AMI"
  type        = string
  default     = "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"
}

variable "key_name" {
  description = "Nom de la paire de clés EC2 (existante dans le compte)"
  type        = string
}

variable "instance_profile_name" {
  description = "Profil IAM existant à attacher aux instances (ex : LabInstanceProfile). null = aucun (par défaut : SSH via bastion, aucun besoin IAM)"
  type        = string
  default     = null
}

variable "app_port" {
  description = "Port HTTP des instances app"
  type        = number
  default     = 80
}

variable "health_check_path" {
  description = "Chemin de health check de l'ALB"
  type        = string
  default     = "/health"
}

# --- Auto Scaling ------------------------------------------------------

variable "asg_min_size" {
  description = "Nombre minimum d'instances"
  type        = number
}

variable "asg_max_size" {
  description = "Nombre maximum d'instances"
  type        = number
}

variable "asg_desired_capacity" {
  description = "Nombre d'instances souhaité au démarrage"
  type        = number
}

variable "cpu_target_percent" {
  description = "Cible de CPU moyen (%) pour le scaling automatique"
  type        = number
  default     = 60
}

# --- Bastion -----------------------------------------------------------

variable "enable_bastion" {
  description = "Crée un bastion SSH dans le premier sous-réseau public"
  type        = bool
  default     = true
}

variable "bastion_instance_type" {
  description = "Type d'instance du bastion"
  type        = string
  default     = "t3.micro"
}

variable "tags" {
  description = "Tags communs (doit contenir Project et Environment, utilisés par Ansible)"
  type        = map(string)
  default     = {}
}
