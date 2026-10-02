terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }

  # State LOCAL, propre à ce dossier (terraform.tfstate ici même, ignoré par
  # Git). Pas de backend S3+DynamoDB : comptes AWS Academy individuels et
  # temporaires, voir docs/rapport.md (section workspaces vs dossiers).
  backend "local" {
    path = "terraform.tfstate"
  }
}

provider "aws" {
  region = var.region
}
