
# AMI UBUNTU
#

data "aws_ami" "ubuntu" {

  most_recent = true

  owners = ["099720109477"]

  filter {
    name = "name"

    values = [
      "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"
    ]
  }
}

#################################################
# LAUNCH TEMPLATE
#################################################

resource "aws_launch_template" "atlasforge" {

  name_prefix = "atlasforge-lt"

  image_id = data.aws_ami.ubuntu.id

  instance_type = "t3.micro"

  key_name = var.key_name

  vpc_security_group_ids = [
    aws_security_group.app.id
  ]

  user_data = base64encode(<<EOF
#!/bin/bash

apt update -y
apt install nginx -y

mkdir -p /var/www/html

echo "ATLASFORGE APP $(hostname)" > /var/www/html/index.html
echo "OK" > /var/www/html/health

systemctl enable nginx
systemctl start nginx
EOF
)

  tag_specifications {

    resource_type = "instance"

    tags = {
      Project = "AtlasForge"
      Role    = "app"
    }
  }
}

#################################################
# AUTO SCALING GROUP
#################################################

resource "aws_autoscaling_group" "atlasforge" {

  name = "atlasforge-asg"

  min_size = 1

  desired_capacity = 1

  max_size = 2

  health_check_type = "ELB"

  health_check_grace_period = 300

  vpc_zone_identifier = [
    aws_subnet.app_a.id,
    aws_subnet.app_b.id
  ]

  target_group_arns = [
    aws_lb_target_group.atlasforge.arn
  ]

  launch_template {

    id = aws_launch_template.atlasforge.id

    version = "$Latest"
  }

  tag {

    key = "Project"

    value = "AtlasForge"

    propagate_at_launch = true
  }

  tag {

    key = "Role"

    value = "app"

    propagate_at_launch = true
  }
}
