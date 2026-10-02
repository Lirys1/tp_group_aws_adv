variable "name_prefix" {
  description = "Préfixe de nommage des ressources (ex : neocargo-staging)"
  type        = string
}

variable "vpc_cidr" {
  description = "Bloc CIDR du VPC (doit être différent entre staging et prod)"
  type        = string

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "vpc_cidr doit être un CIDR IPv4 valide."
  }
}

variable "public_subnet_cidrs" {
  description = "CIDR des sous-réseaux publics (un par AZ, au moins 2 pour l'ALB)"
  type        = list(string)

  validation {
    condition     = length(var.public_subnet_cidrs) >= 2
    error_message = "Il faut au moins 2 sous-réseaux publics (exigence de l'ALB)."
  }
}

variable "app_subnet_cidrs" {
  description = "CIDR des sous-réseaux applicatifs privés (un par AZ)"
  type        = list(string)

  validation {
    condition     = length(var.app_subnet_cidrs) >= 2
    error_message = "Il faut au moins 2 sous-réseaux app (haute disponibilité de l'ASG)."
  }
}

variable "data_subnet_cidrs" {
  description = "CIDR des sous-réseaux de données privés (un par AZ)"
  type        = list(string)

  validation {
    condition     = length(var.data_subnet_cidrs) >= 2
    error_message = "Il faut au moins 2 sous-réseaux data (exigence du DB subnet group RDS)."
  }
}

variable "enable_nat_gateway" {
  description = "Crée une NAT Gateway pour donner un accès sortant aux instances app"
  type        = bool
  default     = true
}

variable "bastion_allowed_cidrs" {
  description = "CIDR autorisés à se connecter en SSH au bastion"
  type        = list(string)
}

variable "app_port" {
  description = "Port HTTP exposé par les instances app"
  type        = number
  default     = 80
}

variable "db_port" {
  description = "Port de la base de données"
  type        = number
  default     = 5432
}

variable "monitoring_port" {
  description = "Port de l'agent de supervision (node_exporter)"
  type        = number
  default     = 9100
}

variable "tags" {
  description = "Tags communs appliqués à toutes les ressources du module"
  type        = map(string)
  default     = {}
}
