# 각 레이어별 보안 그룹 (Bastion, Nginx, Tomcat, CLB, ALB)

#===========================================================
# BASTION 보안 그룹
#===========================================================
resource "aws_security_group" "kwu_prd_vpc_bastion_pub_sg_2a" {
  name        = "KWU-PRD-VPC-BASTION-PUB-SG-2A"
  description = "Security Group for Bastion Public Subnet 2A"
  vpc_id      = aws_vpc.kwu_prd_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "KWU-PRD-VPC-BASTION-PUB-SG-2A"
  }
}

#===========================================================
# NGINX 보안 그룹 (2중화)
#===========================================================
resource "aws_security_group" "kwu_prd_vpc_nginx_pub_sg_2a" {
  name        = "KWU-PRD-VPC-NGINX-PUB-SG-2A"
  description = "Security Group for NGINX Public Subnet 2A"
  vpc_id      = aws_vpc.kwu_prd_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "KWU-PRD-VPC-NGINX-PUB-SG-2A"
  }
}

resource "aws_security_group" "kwu_prd_vpc_nginx_pub_sg_2c" {
  name        = "KWU-PRD-VPC-NGINX-PUB-SG-2C"
  description = "Security Group for NGINX Public Subnet 2C"
  vpc_id      = aws_vpc.kwu_prd_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "KWU-PRD-VPC-NGINX-PUB-SG-2C"
  }
}

#===========================================================
# TOMCAT 보안 그룹 (Private, 2중화)
#===========================================================
resource "aws_security_group" "kwu_prd_vpc_tomcat_pri_sg_2a" {
  name        = "KWU-PRD-VPC-TOMCAT-PRI-SG-2A"
  description = "Security Group for Tomcat Private Subnet 2A"
  vpc_id      = aws_vpc.kwu_prd_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
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
    Name = "KWU-PRD-VPC-TOMCAT-PRI-SG-2A"
  }
}

resource "aws_security_group" "kwu_prd_vpc_tomcat_pri_sg_2c" {
  name        = "KWU-PRD-VPC-TOMCAT-PRI-SG-2C"
  description = "Security Group for Tomcat Private Subnet 2C"
  vpc_id      = aws_vpc.kwu_prd_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
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
    Name = "KWU-PRD-VPC-TOMCAT-PRI-SG-2C"
  }
}

#===========================================================
# CLB 보안 그룹
#===========================================================
resource "aws_security_group" "kwu_prd_vpc_clb_sg" {
  name        = "KWU-PRD-VPC-CLB-SG"
  description = "Security Group for Classic Load Balancer"
  vpc_id      = aws_vpc.kwu_prd_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
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
    Name = "KWU-PRD-VPC-CLB-SG"
  }
}

#===========================================================
# ALB 보안 그룹
#===========================================================
resource "aws_security_group" "kwu_prd_vpc_alb_sg" {
  name        = "KWU-PRD-VPC-ALB-SG"
  description = "Security Group for Application Load Balancer"
  vpc_id      = aws_vpc.kwu_prd_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
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
    Name = "KWU-PRD-VPC-ALB-SG"
  }
}
