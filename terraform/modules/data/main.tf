# =====================================================================
# MODULE DATA
# RDS PostgreSQL + bucket S3 + gestion du secret de la base.
# Le mot de passe RDS n'est plus saisi à la main ni stocké dans un .tfvars :
# il est généré par Terraform (random_password), marqué "sensitive", et
# récupéré par l'équipe via `terraform output -raw db_password`.
# =====================================================================

# ---------------------------------------------------------------------
# Secret : mot de passe maître RDS généré aléatoirement
# RDS refuse les caractères / @ " et espace : on restreint les spéciaux.
# ---------------------------------------------------------------------
resource "random_password" "db" {
  length           = 24
  special          = true
  override_special = "!#$%^&*()-_=+"
}

# ---------------------------------------------------------------------
# RDS PostgreSQL (sous-réseaux data isolés)
# ---------------------------------------------------------------------
resource "aws_db_subnet_group" "this" {
  name       = "${var.name_prefix}-db-subnets"
  subnet_ids = var.data_subnet_ids

  tags = merge(var.tags, { Name = "${var.name_prefix}-db-subnets" })
}

resource "aws_db_instance" "this" {
  identifier     = "${var.name_prefix}-rds"
  engine         = "postgres"
  engine_version = var.db_engine_version
  instance_class = var.db_instance_class

  allocated_storage = var.db_allocated_storage
  storage_type      = "gp2"
  storage_encrypted = true

  db_name  = var.db_name
  username = var.db_username
  password = random_password.db.result
  port     = var.db_port

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [var.rds_security_group_id]
  publicly_accessible    = false
  multi_az               = var.db_multi_az

  backup_retention_period = var.db_backup_retention_days
  deletion_protection     = var.db_deletion_protection
  skip_final_snapshot     = var.db_skip_final_snapshot
  apply_immediately       = true

  tags = merge(var.tags, { Name = "${var.name_prefix}-rds" })
}

# ---------------------------------------------------------------------
# S3 : bucket privé, versionné et chiffré
# ---------------------------------------------------------------------
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "this" {
  bucket = "${var.name_prefix}-${var.bucket_purpose}-${random_id.bucket_suffix.hex}"

  # true = terraform destroy vide le bucket (versions incluses) avant de le
  # supprimer : indispensable pour un environnement « jetable » comme staging.
  force_destroy = var.bucket_force_destroy

  tags = merge(var.tags, { Name = "${var.name_prefix}-${var.bucket_purpose}" })
}

resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id

  versioning_configuration {
    status = var.bucket_versioning ? "Enabled" : "Suspended"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
