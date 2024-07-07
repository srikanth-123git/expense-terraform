resource "aws_security_group" "main" {
  name        = "${var.component}-${var.env}-sg"
  description = "${var.component}-${var.env}-sg"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = var.app_port
    to_port     = var.app_port
    protocol    = "TCP"
    cidr_blocks = var.server_app_port_sg_cidr
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "TCP"
    cidr_blocks = var.bastion_nodes
  }

  ingress {
    from_port   = 9100
    to_port     = 9100
    protocol    = "TCP"
    cidr_blocks = var.prometheus_nodes
  }

  ingress {
    from_port   = 2019
    to_port     = 2019
    protocol    = "TCP"
    cidr_blocks = var.prometheus_nodes
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.component}-${var.env}-sg"
  }
}

resource "aws_launch_template" "main" {
  name                   = "${var.component}-${var.env}"
  image_id               = data.aws_ami.ami.id
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.main.id]

  block_device_mappings {
    device_name = "/dev/sda1"

    ebs {
      volume_size           = 10
      encrypted             = true
      kms_key_id            = var.kms_key_id
      delete_on_termination = true
    }
  }

  user_data = base64encode(templatefile("${path.module}/userdata.sh", {
    component   = var.component
    env         = var.env
    vault_token = var.vault_token
  }))

}

resource "aws_autoscaling_group" "main" {
  name                = "${var.component}-${var.env}"
  desired_capacity    = var.min_capacity
  max_size            = var.max_capacity
  min_size            = var.min_capacity
  vpc_zone_identifier = var.subnets
  target_group_arns   = [aws_lb_target_group.main.arn]

  launch_template {
    id      = aws_launch_template.main.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.component}-${var.env}"
    propagate_at_launch = true
  }

  tag {
    key                 = "monitor"
    value               = "yes"
    propagate_at_launch = true
  }

  tag {
    key                 = "env"
    value               = var.env
    propagate_at_launch = true
  }

}

resource "aws_autoscaling_policy" "main" {
  name                   = "target-cpu"
  autoscaling_group_name = aws_autoscaling_group.main.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 50.0
  }
}

resource "aws_lb_target_group" "main" {
  name                 = "${var.env}-${var.component}-tg"
  port                 = var.app_port
  protocol             = "HTTP"
  vpc_id               = var.vpc_id
  deregistration_delay = 15

  health_check {
    healthy_threshold   = 2
    interval            = 5
    path                = "/health"
    port                = var.app_port
    timeout             = 2
    unhealthy_threshold = 2
  }
}


resource "aws_security_group" "load-balancer" {
  name        = "${var.component}-${var.env}-lb-sg"
  description = "${var.component}-${var.env}-lb-sg"
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = var.lb_ports
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "TCP"
      cidr_blocks = var.lb_app_port_sg_cidr
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.component}-${var.env}-sg"
  }
}

resource "aws_lb" "main" {
  name               = "${var.env}-${var.component}-alb"
  internal           = var.lb_type == "public" ? false : true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.load-balancer.id]
  subnets            = var.lb_subnets

  tags = {
    Environment = "${var.env}-${var.component}-alb"
  }
}

resource "aws_route53_record" "load-balancer" {
  name    = "${var.component}-${var.env}"
  type    = "CNAME"
  zone_id = var.zone_id
  records = [aws_lb.main.dns_name]
  ttl     = 30
}

resource "aws_lb_listener" "frontend-http" {
  count             = var.lb_type == "public" ? 1 : 0
  load_balancer_arn = aws_lb.main.arn
  port              = var.app_port
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }

}

resource "aws_lb_listener" "frontend-https" {
  count             = var.lb_type == "public" ? 1 : 0
  load_balancer_arn = aws_lb.main.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }

}

resource "aws_lb_listener" "backend" {
  count             = var.lb_type != "public" ? 1 : 0
  load_balancer_arn = aws_lb.main.arn
  port              = var.app_port
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }

}
