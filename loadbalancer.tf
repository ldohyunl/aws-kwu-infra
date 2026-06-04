# CLB (Classic Load Balancer) 및 ALB (Application Load Balancer)

#===========================================================
# 05. CLB (Classic Load Balancer)
#===========================================================
resource "aws_elb" "kwu_prd_vpc_clb" {
  name            = "KWU-PRD-VPC-CLB"
  internal        = false
  security_groups = [aws_security_group.kwu_prd_vpc_clb_sg.id]

  subnets = [
    aws_subnet.kwu_prd_vpc_nginx_pub_2a.id,
    aws_subnet.kwu_prd_vpc_nginx_pub_2c.id,
  ]

  listener {
    instance_port     = 80
    instance_protocol = "HTTP"
    lb_port           = 80
    lb_protocol       = "HTTP"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    target              = "HTTP:80/"
    interval            = 30
  }

  instances = [
    aws_instance.kwu_prd_vpc_nginx_pub_2a.id,
    aws_instance.kwu_prd_vpc_nginx_pub_2c.id,
  ]

  cross_zone_load_balancing = true

  tags = {
    Name = "KWU-PRD-VPC-CLB"
  }
}

#===========================================================
# 06. ALB (Application Load Balancer)
#===========================================================

# ALB 대상 그룹
resource "aws_lb_target_group" "kwu_prd_vpc_alb_tg" {
  name     = "KWU-PRD-VPC-ALB-TG"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.kwu_prd_vpc.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Name = "KWU-PRD-VPC-ALB-TG"
  }
}

# NGINX 2A 대상 등록
resource "aws_lb_target_group_attachment" "nginx_2a" {
  target_group_arn = aws_lb_target_group.kwu_prd_vpc_alb_tg.arn
  target_id        = aws_instance.kwu_prd_vpc_nginx_pub_2a.id
  port             = 80
}

# NGINX 2C 대상 등록
resource "aws_lb_target_group_attachment" "nginx_2c" {
  target_group_arn = aws_lb_target_group.kwu_prd_vpc_alb_tg.arn
  target_id        = aws_instance.kwu_prd_vpc_nginx_pub_2c.id
  port             = 80
}

# ALB 생성
resource "aws_lb" "kwu_prd_vpc_alb" {
  name               = "KWU-PRD-VPC-ALB"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.kwu_prd_vpc_alb_sg.id]

  subnets = [
    aws_subnet.kwu_prd_vpc_nginx_pub_2a.id,
    aws_subnet.kwu_prd_vpc_nginx_pub_2c.id,
  ]

  tags = {
    Name = "KWU-PRD-VPC-ALB"
  }
}

# ALB HTTP 80 리스너
resource "aws_lb_listener" "alb_http" {
  load_balancer_arn = aws_lb.kwu_prd_vpc_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.kwu_prd_vpc_alb_tg.arn
  }
}

# ALB HTTPS 443 리스너 (ACM 인증서 필요)
resource "aws_lb_listener" "alb_https" {
  load_balancer_arn = aws_lb.kwu_prd_vpc_alb.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = data.aws_acm_certificate.main.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.kwu_prd_vpc_alb_tg.arn
  }
}
