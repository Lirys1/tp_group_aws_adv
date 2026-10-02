variable "name_prefix" {
  description = "Préfixe de nommage des ressources (minuscules, ex : neocargo-staging)"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.name_prefix))
    error_message = "name_prefix doit être en minuscules (contrainte des noms de bucket S3 et des identifiants RDS)."
  }
}

# --- Entrées venant du module network --------------------------------

variable "data_subnet_ids" {
  description = "Sous-réseaux data privés pour le DB subnet group (au moins 2 AZ)"
  type        = list(string)
}

variable "rds_security_group_id" {
  description = "Security group de la base RDS"
  type        = string
}

# --- RDS ---------------------------------------------------------------

variable "db_instance_class" {
  description = "Classe d'instance RDS"
  type        = string
}

variable "db_engine_version" {
  description = "Version majeure de PostgreSQL"
  type        = string
  default     = "15"
}

variable "db_allocated_storage" {
  description = "Stockage alloué (Go)"
  type        = number
  default     = 20
}

variable "db_name" {
  description = "Nom de la base applicative"
  type        = string
}

variable "db_username" {
  description = "Utilisateur maître de la base"
  type        = string
  default     = "trackfleet_admin"
}

variable "db_port" {
  description = "Port PostgreSQL"
  type        = number
  default     = 5432
}

variable "db_multi_az" {
  description = "Déploiement Multi-AZ (coûteux, désactivé en TP)"
  type        = bool
  default     = false
}

variable "db_backup_retention_days" {
  description = "Durée de rétention des sauvegardes automatiques (0 = désactivées)"
  type        = number
  default     = 0
}

variable "db_deletion_protection" {
  description = "Protection contre la suppression de la base"
  type        = bool
  default     = false
}

variable "db_skip_final_snapshot" {
  description = "Ne pas créer de snapshot final au destroy"
  type        = bool
  default     = true
}

# --- S3 ----------------------------------------------------------------

variable "bucket_purpose" {
  description = "Suffixe fonctionnel du bucket (ex : assets)"
  type        = string
  default     = "assets"
}

variable "bucket_versioning" {
  description = "Active le versioning du bucket"
  type        = bool
  default     = true
}

variable "bucket_force_destroy" {
  description = "Autorise terraform destroy à vider puis supprimer le bucket"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags communs appliqués à toutes les ressources du module"
  type        = map(string)
  default     = {}
}
