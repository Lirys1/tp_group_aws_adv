# =====================================================================
# ENVIRONNEMENT — appelle les 3 modules communs.
# Ce fichier est identique entre staging/ et prod/ : seules les valeurs
# de terraform.tfvars changent. Le state est local à ce dossier, donc
# un apply ici ne peut jamais toucher l'autre environnement.
# =====================================================================

locals {
  name_prefix = "${var.project}-${var.environment}"

  # Tags communs : Project + Environment servent de filtre à l'inventaire
  # dynamique Ansible (inventory/aws_ec2.yml).
  common_tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

module "network" {
  source = "../../modules/network"

  name_prefix           = local.name_prefix
  vpc_cidr              = var.vpc_cidr
  public_subnet_cidrs   = var.public_subnet_cidrs
  app_subnet_cidrs      = var.app_subnet_cidrs
  data_subnet_cidrs     = var.data_subnet_cidrs
  enable_nat_gateway    = var.enable_nat_gateway
  bastion_allowed_cidrs = var.bastion_allowed_cidrs
  tags                  = local.common_tags
}

module "compute" {
  source = "../../modules/compute"

  name_prefix               = local.name_prefix
  vpc_id                    = module.network.vpc_id
  public_subnet_ids         = module.network.public_subnet_ids
  app_subnet_ids            = module.network.app_subnet_ids
  alb_security_group_id     = module.network.alb_security_group_id
  app_security_group_id     = module.network.app_security_group_id
  bastion_security_group_id = module.network.bastion_security_group_id

  instance_type         = var.instance_type
  key_name              = var.key_name
  instance_profile_name = var.instance_profile_name
  asg_min_size          = var.asg_min_size
  asg_max_size          = var.asg_max_size
  asg_desired_capacity  = var.asg_desired_capacity
  enable_bastion        = var.enable_bastion
  tags                  = local.common_tags

  # Les instances font apt install au démarrage : la NAT doit exister avant
  depends_on = [module.network]
}

module "data" {
  source = "../../modules/data"

  name_prefix           = local.name_prefix
  data_subnet_ids       = module.network.data_subnet_ids
  rds_security_group_id = module.network.rds_security_group_id

  db_instance_class        = var.db_instance_class
  db_name                  = var.db_name
  db_backup_retention_days = var.db_backup_retention_days
  bucket_force_destroy     = var.bucket_force_destroy
  tags                     = local.common_tags
}
