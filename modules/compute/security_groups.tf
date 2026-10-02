# CONFIGURATION DU LOAD BALANCER


resource "aws_security_group" "alb" {

  name = "atlasforge-alb-sg"

  vpc_id = aws_vpc.atlasforge.id

  ingress {

    description = "HTTP depuis Internet"

    from_port = 80
    to_port   = 80

    protocol = "tcp"

    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {

    from_port = 0
    to_port   = 0

    protocol = "-1"

    cidr_blocks = ["0.0.0.0/0"]
  }
}


# CONSTRUCTION DE APPLICATIF


resource "aws_security_group" "app" {

  name = "atlasforge-app-sg"

  vpc_id = aws_vpc.atlasforge.id

  ingress {

    description = "Uniquement depuis ALB"

    from_port = 80
    to_port   = 80

    protocol = "tcp"

    security_groups = [
      aws_security_group.alb.id
    ]
  }

  ingress {
    description     = "SSH depuis le Bastion"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
  }

  egress {

    from_port = 0
    to_port   = 0

    protocol = "-1"

    cidr_blocks = ["0.0.0.0/0"]
  }
}


# parameters DATABASE


resource "aws_security_group" "rds" {

  name = "atlasforge-rds-sg"

  vpc_id = aws_vpc.atlasforge.id

  ingress {

    description = "PostgreSQL depuis applicatif"

    from_port = 5432
    to_port   = 5432

    protocol = "tcp"

    security_groups = [
      aws_security_group.app.id
    ]
  }

  egress {

    from_port = 0
    to_port   = 0

    protocol = "-1"

    cidr_blocks = ["0.0.0.0/0"]
  }
}
