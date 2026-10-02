# VPC principal du projet AtlasForge

resource "aws_vpc" "atlasforge" {

  cidr_block = "10.42.0.0/16"

  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "atlasforge-vpc"
  }
}

# Recuperation dynamique des AZ

data "aws_availability_zones" "available" {}

# Internet Gateway pour les zones publiques

resource "aws_internet_gateway" "igw" {

  vpc_id = aws_vpc.atlasforge.id

  tags = {
    Name = "atlasforge-igw"
  }
}

###################################################
# SUBNETS PUBLICS
###################################################

resource "aws_subnet" "public_a" {

  vpc_id = aws_vpc.atlasforge.id

  cidr_block = "10.42.1.0/24"

  availability_zone = data.aws_availability_zones.available.names[0]

  map_public_ip_on_launch = true

  tags = {
    Name = "atlasforge-public-a"
  }
}

resource "aws_subnet" "public_b" {

  vpc_id = aws_vpc.atlasforge.id

  cidr_block = "10.42.2.0/24"

  availability_zone = data.aws_availability_zones.available.names[1]

  map_public_ip_on_launch = true

  tags = {
    Name = "atlasforge-public-b"
  }
}

###################################################
# SUBNETS APPLICATIFS
###################################################

resource "aws_subnet" "app_a" {

  vpc_id = aws_vpc.atlasforge.id

  cidr_block = "10.42.10.0/24"

  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "atlasforge-app-a"
  }
}

resource "aws_subnet" "app_b" {

  vpc_id = aws_vpc.atlasforge.id

  cidr_block = "10.42.11.0/24"

  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    Name = "atlasforge-app-b"
  }
}

###################################################
# SUBNETS DATABASE
###################################################

resource "aws_subnet" "db_a" {

  vpc_id = aws_vpc.atlasforge.id

  cidr_block = "10.42.20.0/24"

  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "atlasforge-db-a"
  }
}

resource "aws_subnet" "db_b" {

  vpc_id = aws_vpc.atlasforge.id

  cidr_block = "10.42.21.0/24"

  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    Name = "atlasforge-db-b"
  }
}
