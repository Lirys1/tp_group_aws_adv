# =====================================================================
# STAGING — environnement « jetable » de pré-production
# Fichier versionné : AUCUN secret ici (le mot de passe RDS est généré
# par Terraform). Pour une valeur perso, utilisez -var ou secrets.auto.tfvars.
# =====================================================================

environment = "staging"
region      = "eu-west-3"

# --- Réseau : plage 10.10.0.0/16 (prod = 10.20.0.0/16, aucun chevauchement)
vpc_cidr            = "10.10.0.0/16"
public_subnet_cidrs = ["10.10.1.0/24", "10.10.2.0/24"]
app_subnet_cidrs    = ["10.10.11.0/24", "10.10.12.0/24"]
data_subnet_cidrs   = ["10.10.21.0/24", "10.10.22.0/24"]

# A restreindre à votre IP publique (ex : ["203.0.113.10/32"])
bastion_allowed_cidrs = ["0.0.0.0/0"]

# --- Compute : dimensionnement minimal
instance_type        = "t3.micro"
asg_min_size         = 1
asg_max_size         = 2
asg_desired_capacity = 1

# Paire de clés EC2 du compte de la personne qui fait l'apply
key_name = "ipssi-tp"

# --- Données
db_instance_class        = "db.t3.micro"
db_backup_retention_days = 0    # jetable : pas de sauvegarde
bucket_force_destroy     = true # destroy/recreate fréquents
