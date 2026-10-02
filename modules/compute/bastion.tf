# BASTION.TF - Instance de rebond SSH
# Rôle : Permet d'accéder aux sous-réseaux privés de l'ASG depuis l'extérieur

resource "aws_security_group" "bastion" {
  name        = "atlasforge-bastion-sg"
  description = "SG du bastion : autorise uniquement le SSH entrant"
  vpc_id      = aws_vpc.atlasforge.id

  ingress {
    description = "SSH depuis Internet"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "atlasforge-bastion-sg"
  }
}

resource "aws_instance" "bastion" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.public_a.id # Utilise ton sous-réseau public défini dans network.tf
  associate_public_ip_address = true                    # Donne l'IP publique indispensable pour le ProxyJump Ansible
  key_name                    = var.key_name
  vpc_security_group_ids      = [aws_security_group.bastion.id]

  tags = {
    Name = "atlasforge-bastion"
  }
}
