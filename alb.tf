#This code was made only for the school project by tdupuis and may not be used otherwise 
# LOAD BALANCER PUBLIC


resource "aws_lb" "atlasforge" {

  name = "atlasforge-alb"

  internal = false

  load_balancer_type = "application"

  security_groups = [
    aws_security_group.alb.id
  ]

  subnets = [
    aws_subnet.public_a.id,
    aws_subnet.public_b.id
  ]

  tags = {
    Name = "atlasforge-alb"
  }
}

# TARGET GROUP IN THIS CASE FOR THE PORT 80


resource "aws_lb_target_group" "atlasforge" {

  name = "atlasforge-tg"

  port = 80

  protocol = "HTTP"

  target_type = "instance"

  vpc_id = aws_vpc.atlasforge.id

  health_check {

    enabled = true

    path = "/health"

    protocol = "HTTP"

    healthy_threshold = 2

    unhealthy_threshold = 2

    interval = 30

    timeout = 5

    matcher = "200"
  }
}

# LISTENER PORT HTTP


resource "aws_lb_listener" "http" {

  load_balancer_arn = aws_lb.atlasforge.arn

  port = 80

  protocol = "HTTP"

  default_action {

    type = "forward"

    target_group_arn = aws_lb_target_group.atlasforge.arn
  }
}
