# =====================================================================
# MODULE NETWORK
# VPC 3 niveaux : public (ALB, bastion, NAT) / app (ASG) / data (RDS)
# + routage + security groups.
# Aucune valeur propre à un environnement n'est codée en dur ici :
# tout (CIDR, noms, ports autorisés) arrive par les variables.
# =====================================================================

data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  azs = slice(data.aws_availability_zones.available.names, 0, length(var.public_subnet_cidrs))
}

# ---------------------------------------------------------------------
# VPC + Internet Gateway
# ---------------------------------------------------------------------
resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(var.tags, { Name = "${var.name_prefix}-vpc" })
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, { Name = "${var.name_prefix}-igw" })
}

# ---------------------------------------------------------------------
# Sous-réseaux (un par AZ et par niveau)
# ---------------------------------------------------------------------
resource "aws_subnet" "public" {
  count = length(var.public_subnet_cidrs)

  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = local.azs[count.index]
  map_public_ip_on_launch = true

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-public-${local.azs[count.index]}"
    Tier = "public"
  })
}

resource "aws_subnet" "app" {
  count = length(var.app_subnet_cidrs)

  vpc_id            = aws_vpc.this.id
  cidr_block        = var.app_subnet_cidrs[count.index]
  availability_zone = local.azs[count.index]

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-app-${local.azs[count.index]}"
    Tier = "app"
  })
}

resource "aws_subnet" "data" {
  count = length(var.data_subnet_cidrs)

  vpc_id            = aws_vpc.this.id
  cidr_block        = var.data_subnet_cidrs[count.index]
  availability_zone = local.azs[count.index]

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-data-${local.azs[count.index]}"
    Tier = "data"
  })
}

# ---------------------------------------------------------------------
# NAT Gateway : indispensable pour que les instances privées (niveau app)
# puissent faire apt install / télécharger des paquets.
# Une seule NAT (dans la 1re AZ publique) pour limiter le coût en TP.
# ---------------------------------------------------------------------
resource "aws_eip" "nat" {
  count  = var.enable_nat_gateway ? 1 : 0
  domain = "vpc"

  tags = merge(var.tags, { Name = "${var.name_prefix}-nat-eip" })
}

resource "aws_nat_gateway" "this" {
  count = var.enable_nat_gateway ? 1 : 0

  allocation_id = aws_eip.nat[0].id
  subnet_id     = aws_subnet.public[0].id

  tags = merge(var.tags, { Name = "${var.name_prefix}-nat" })

  depends_on = [aws_internet_gateway.this]
}

# ---------------------------------------------------------------------
# Tables de routage
# ---------------------------------------------------------------------

# Public : sortie Internet via l'IGW
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = merge(var.tags, { Name = "${var.name_prefix}-public-rt" })
}

resource "aws_route_table_association" "public" {
  count = length(aws_subnet.public)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# App : sortie Internet uniquement via la NAT (pas d'IP publique)
resource "aws_route_table" "app" {
  vpc_id = aws_vpc.this.id

  dynamic "route" {
    for_each = var.enable_nat_gateway ? [1] : []
    content {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = aws_nat_gateway.this[0].id
    }
  }

  tags = merge(var.tags, { Name = "${var.name_prefix}-app-rt" })
}

resource "aws_route_table_association" "app" {
  count = length(aws_subnet.app)

  subnet_id      = aws_subnet.app[count.index].id
  route_table_id = aws_route_table.app.id
}

# Data : table isolée, uniquement la route locale du VPC (aucune sortie)
resource "aws_route_table" "data" {
  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, { Name = "${var.name_prefix}-data-rt" })
}

resource "aws_route_table_association" "data" {
  count = length(aws_subnet.data)

  subnet_id      = aws_subnet.data[count.index].id
  route_table_id = aws_route_table.data.id
}

# ---------------------------------------------------------------------
# Security groups (chaîne de confiance : Internet -> ALB -> app -> RDS)
# ---------------------------------------------------------------------
resource "aws_security_group" "alb" {
  name        = "${var.name_prefix}-alb-sg"
  description = "ALB - HTTP depuis Internet"
  vpc_id      = aws_vpc.this.id

  ingress {
    description = "HTTP depuis Internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Sortie vers les instances app"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${var.name_prefix}-alb-sg" })
}

resource "aws_security_group" "bastion" {
  name        = "${var.name_prefix}-bastion-sg"
  description = "Bastion - SSH depuis les CIDR autorises uniquement"
  vpc_id      = aws_vpc.this.id

  ingress {
    description = "SSH administrateurs"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.bastion_allowed_cidrs
  }

  egress {
    description = "Rebond vers les sous-reseaux prives"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${var.name_prefix}-bastion-sg" })
}

resource "aws_security_group" "app" {
  name        = "${var.name_prefix}-app-sg"
  description = "Instances app - HTTP depuis ALB, SSH et metriques depuis bastion"
  vpc_id      = aws_vpc.this.id

  ingress {
    description     = "HTTP uniquement depuis l ALB"
    from_port       = var.app_port
    to_port         = var.app_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  ingress {
    description     = "SSH depuis le bastion (Ansible)"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
  }

  ingress {
    description     = "node_exporter depuis le bastion (supervision)"
    from_port       = var.monitoring_port
    to_port         = var.monitoring_port
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
  }

  egress {
    description = "Sortie (apt via NAT, RDS)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${var.name_prefix}-app-sg" })
}

resource "aws_security_group" "rds" {
  name        = "${var.name_prefix}-rds-sg"
  description = "RDS - PostgreSQL depuis les instances app uniquement"
  vpc_id      = aws_vpc.this.id

  ingress {
    description     = "PostgreSQL depuis le niveau app"
    from_port       = var.db_port
    to_port         = var.db_port
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }

  tags = merge(var.tags, { Name = "${var.name_prefix}-rds-sg" })
}
