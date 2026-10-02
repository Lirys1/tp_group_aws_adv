variable "region" {
  description = "Region AWS de deploiement"
  default     = "eu-west-3"
}

variable "project_name" {
  description = "Prefixe utilise pour nommer les ressources"
  default     = "atlasforge"
}

variable "key_name" {
  description = "Nom de la paire de cles EC2"
  type        = string
}

variable "db_password" {
  description = "Mot de passe administrateur PostgreSQL"
  type        = string
  sensitive   = true
}
