# =====================================================================
# MODULE COMPUTE
# Launch Template + Target Group + ALB + Auto Scaling Group + bastion.
# Le dimensionnement (type d'instance, min/max/desired) et les noms sont
# des paramètres : staging et prod appellent ce même code.
# =====================================================================

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = [var.ami_owner]

  filter {
    name   = "name"
    values = [var.ami_name_filter]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

locals {
  # Tags posés sur les instances : Environment et Role sont utilisés par
  # l'inventaire dynamique Ansible pour cibler un environnement précis.
  app_instance_tags = merge(var.tags, {
    Name = "${var.name_prefix}-app"
    Role = "app"
  })
}

# ---------------------------------------------------------------------
# Launch Template
# Le user_data se limite à un bootstrap minimal (nginx + /health) pour que
# l'ALB voie l'instance saine avant le passage d'Ansible ; la vraie
# configuration est faite par les rôles Ansible webserver/monitoring.
# ---------------------------------------------------------------------
resource "aws_launch_template" "app" {
  name_prefix   = "${var.name_prefix}-lt-"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  key_name      = var.key_name

  vpc_security_group_ids = [var.app_security_group_id]

  # Learner Lab : on réutilise le profil fourni, jamais de rôle IAM créé
  dynamic "iam_instance_profile" {
    for_each = var.instance_profile_name == null ? [] : [1]
    content {
      name = var.instance_profile_name
    }
  }

  metadata_options {
    http_tokens   = "required" # IMDSv2 obligatoire
    http_endpoint = "enabled"
  }

  user_data = base64encode(<<-EOF
    #!/bin/bash
    set -e
    apt-get update -y
    apt-get install -y nginx
    echo "OK" > /var/www/html${var.health_check_path}
    systemctl enable --now nginx
  EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags          = local.app_instance_tags
  }

  tag_specifications {
    resource_type = "volume"
    tags          = merge(var.tags, { Name = "${var.name_prefix}-app-volume" })
  }

  tags = merge(var.tags, { Name = "${var.name_prefix}-lt" })
}

# ---------------------------------------------------------------------
# ALB + Target Group + Listener
# ---------------------------------------------------------------------
resource "aws_lb" "this" {
  name               = "${var.name_prefix}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_security_group_id]
  subnets            = var.public_subnet_ids

  tags = merge(var.tags, { Name = "${var.name_prefix}-alb" })
}

resource "aws_lb_target_group" "app" {
  name        = "${var.name_prefix}-tg"
  port        = var.app_port
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = var.vpc_id

  health_check {
    enabled             = true
    path                = var.health_check_path
    protocol            = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 30
    timeout             = 5
    matcher             = "200"
  }

  tags = merge(var.tags, { Name = "${var.name_prefix}-tg" })
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

# ---------------------------------------------------------------------
# Auto Scaling Group (dans les sous-réseaux app privés)
# ---------------------------------------------------------------------
resource "aws_autoscaling_group" "app" {
  name                      = "${var.name_prefix}-asg"
  min_size                  = var.asg_min_size
  max_size                  = var.asg_max_size
  desired_capacity          = var.asg_desired_capacity
  vpc_zone_identifier       = var.app_subnet_ids
  target_group_arns         = [aws_lb_target_group.app.arn]
  health_check_type         = "ELB"
  health_check_grace_period = 300

  launch_template {
    id      = aws_launch_template.app.id
    version = aws_launch_template.app.latest_version
  }

  # Remplace progressivement les instances quand le Launch Template change
  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
  }

  dynamic "tag" {
    for_each = local.app_instance_tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }
}

# Scaling automatique sur la charge CPU moyenne
resource "aws_autoscaling_policy" "cpu" {
  name                   = "${var.name_prefix}-cpu-target"
  autoscaling_group_name = aws_autoscaling_group.app.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = var.cpu_target_percent
  }
}

# ---------------------------------------------------------------------
# Bastion (rebond SSH pour Ansible vers les instances privées)
# ---------------------------------------------------------------------
resource "aws_instance" "bastion" {
  count = var.enable_bastion ? 1 : 0

  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.bastion_instance_type
  subnet_id                   = var.public_subnet_ids[0]
  associate_public_ip_address = true
  key_name                    = var.key_name
  vpc_security_group_ids      = [var.bastion_security_group_id]

  metadata_options {
    http_tokens   = "required"
    http_endpoint = "enabled"
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-bastion"
    Role = "bastion"
  })
}
