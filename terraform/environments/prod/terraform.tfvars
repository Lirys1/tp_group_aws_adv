# =====================================================================
# PROD — environnement de référence
# Mêmes modules que staging : seules ces valeurs changent.
# Fichier versionné : AUCUN secret ici.
# =====================================================================

environment = "prod"
region      = "eu-west-3"

# --- Réseau : plage 10.20.0.0/16 (staging = 10.10.0.0/16)
vpc_cidr            = "10.20.0.0/16"
public_subnet_cidrs = ["10.20.1.0/24", "10.20.2.0/24"]
app_subnet_cidrs    = ["10.20.11.0/24", "10.20.12.0/24"]
data_subnet_cidrs   = ["10.20.21.0/24", "10.20.22.0/24"]

# A restreindre à votre IP publique (ex : ["203.0.113.10/32"])
bastion_allowed_cidrs = ["0.0.0.0/0"]

# --- Compute : dimensionnement supérieur (haute dispo sur 2 AZ minimum)
instance_type        = "t3.small"
asg_min_size         = 2
asg_max_size         = 4
asg_desired_capacity = 2

# Paire de clés EC2 du compte de la personne qui fait l'apply
key_name = "ipssi-tp"

# --- Données (db.t3.micro imposé par le quota AWS Academy)
db_instance_class        = "db.t3.micro"
db_backup_retention_days = 1     # sauvegarde quotidienne conservée 1 jour
bucket_force_destroy     = false # protège les objets contre un destroy accidentel
