# VPC, 서브넷 6개, IGW, NAT, 라우팅 테이블

#===========================================================
# 01. VPC 생성
#===========================================================
resource "aws_vpc" "kwu_prd_vpc" {
  # IPv4 CIDR 블록 대역 지정 
  cidr_block = "10.250.0.0/16"

  # RDS 가동을 위한 필수 DNS 호스트 이름 설정 
  enable_dns_hostnames = true
  enable_dns_support   = true

  #이름태그 매핑 
  tags = {
    Name = "KWU-PRD-VPC"
  }
}

#===========================================================
# 02-1. Public Subnet 생성
#===========================================================


# 1) AZ : 2A - NGINX 퍼블릭 서브넷
resource "aws_subnet" "kwu_prd_vpc_nginx_pub_2a" {
  vpc_id                  = aws_vpc.kwu_prd_vpc.id #위에서 생성한 VPC id 참고해서 연결
  cidr_block              = "10.250.1.0/24"
  availability_zone       = "ap-northeast-2a"
  map_public_ip_on_launch = true # 퍼블릭 서브넷 내 인스턴스에 공인 IP 자동 할당

  tags = {
    Name = "KWU-PRD-VPC-NGINX-PUB-2A"
  }
}

# 1) AZ : 2A - BASTION 퍼블릭 서브넷
resource "aws_subnet" "kwu_prd_vpc_bastion_pub_2a" {
  vpc_id                  = aws_vpc.kwu_prd_vpc.id
  cidr_block              = "10.250.4.0/24"
  availability_zone       = "ap-northeast-2a"
  map_public_ip_on_launch = true 

  tags = {
    Name = "KWU-PRD-VPC-BASTION-PUB-2A"
  }
}

# 2) AZ : 2C - NGINX 퍼블릭 서브넷 (2중화 구성)
resource "aws_subnet" "kwu_prd_vpc_nginx_pub_2c" {
  vpc_id                  = aws_vpc.kwu_prd_vpc.id
  cidr_block              = "10.250.11.0/24"
  availability_zone       = "ap-northeast-2c"
  map_public_ip_on_launch = true 

  tags = {
    Name = "KWU-PRD-VPC-NGINX-PUB-2C"
  }
}

#===========================================================
# 02-2. Private Subnet 생성
#===========================================================

# 1) AZ : 2A - TOMCAT 프라이빗 서브넷
resource "aws_subnet" "kwu_prd_vpc_tomcat_pri_2a" {
  vpc_id            = aws_vpc.kwu_prd_vpc.id
  cidr_block        = "10.250.2.0/24"
  availability_zone = "ap-northeast-2a"

  tags = {
    Name = "KWU-PRD-VPC-TOMCAT-PRI-2A"
  }
}

# 2) AZ : 2C - TOMCAT 프라이빗 서브넷 (2중화 구성)
resource "aws_subnet" "kwu_prd_vpc_tomcat_pri_2c" {
  vpc_id            = aws_vpc.kwu_prd_vpc.id
  cidr_block        = "10.250.12.0/24"
  availability_zone = "ap-northeast-2c"

  tags = {
    Name = "KWU-PRD-VPC-TOMCAT-PRI-2C"
  }
}

#===========================================================
# 03. 인터넷 게이트웨이 설치
#===========================================================
resource "aws_internet_gateway" "kwu_prd_vpc_igw" {
  # 앞에서 생성한 KWU-PRD-VPC의 ID를 지정하여 자동으로 연결(Attach)합니다.
  vpc_id = aws_vpc.kwu_prd_vpc.id

  tags = {
    Name = "KWU-PRD-VPC-IGW"
  }
}

#===========================================================
# 04. NAT 게이트웨이 설치
#===========================================================

# 1) NAT 게이트웨이용 탄력적 IP (EIP) 할당
resource "aws_eip" "kwu_prd_vpc_ngw_eip_2a" {
  domain = "vpc"

  # 인터넷 게이트웨이(IGW)가 있어야 VPC용 EIP를 안정적으로 할당받을 수 있으므로 의존성 명시
  depends_on = [aws_internet_gateway.kwu_prd_vpc_igw]

  tags = {
    Name = "KWU-PRD-VPC-NGW-EIP-2A"
  }
}

# 2) NAT 게이트웨이 생성 (Public Subnet 2A에 배치)
resource "aws_nat_gateway" "kwu_prd_vpc_ngw_2a" {
  # 위에서 생성한 탄력적 IP(EIP)의 할당 ID를 연결합니다.
  allocation_id = aws_eip.kwu_prd_vpc_ngw_eip_2a.id
  
  # 요구사항대로 'KWU-PRD-VPC-NGINX-PUB-2A' 서브넷의 ID를 지정합니다.
  subnet_id     = aws_subnet.kwu_prd_vpc_nginx_pub_2a.id

  tags = {
    Name = "KWU-PRD-VPC-NGW-2A"
  }

  # 게이트웨이가 완전히 정상 작동하기 위해 IGW 생성을 먼저 보장합니다.
  depends_on = [aws_internet_gateway.kwu_prd_vpc_igw]
}

#===========================================================
# 05-1. Routing 테이블 생성 및 05-2. 라우팅 편집
#===========================================================

# 1) Public 영역 라우팅 테이블 생성 및 IGW 라우팅 추가
resource "aws_route_table" "kwu_prd_vpc_rt_pub" {
  vpc_id = aws_vpc.kwu_prd_vpc.id

  # 0.0.0.0/0 경로를 인터넷 게이트웨이(IGW)로 지정
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.kwu_prd_vpc_igw.id
  }

  tags = {
    Name = "KWU-PRD-VPC-RT-PUB"
  }
}

# 2) Private 영역 라우팅 테이블 생성 및 NGW 라우팅 추가
resource "aws_route_table" "kwu_prd_vpc_rt_pri" {
  vpc_id = aws_vpc.kwu_prd_vpc.id

  # 0.0.0.0/0 경로를 NAT 게이트웨이(NGW)로 지정 (프라이빗 존 인터넷 통신용)
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.kwu_prd_vpc_ngw_2a.id
  }

  tags = {
    Name = "KWU-PRD-VPC-RT-PRI"
  }
}

#===========================================================
# 05-2. 라우팅 테이블 - 서브넷 명시적 연결 (Association)
#===========================================================

# --- Public 라우팅 테이블 연결 ---

# NGINX 퍼블릭 서브넷 2A 연결
resource "aws_route_table_association" "kwu_prd_vpc_rt_pub_assoc_nginx_2a" {
  subnet_id      = aws_subnet.kwu_prd_vpc_nginx_pub_2a.id
  route_table_id = aws_route_table.kwu_prd_vpc_rt_pub.id
}

# NGINX 퍼블릭 서브넷 2C 연결 (2중화)
resource "aws_route_table_association" "kwu_prd_vpc_rt_pub_assoc_nginx_2c" {
  subnet_id      = aws_subnet.kwu_prd_vpc_nginx_pub_2c.id
  route_table_id = aws_route_table.kwu_prd_vpc_rt_pub.id
}

# BASTION 퍼블릭 서브넷 2A 연결 (추후 추가를 위해 미리 매핑)
resource "aws_route_table_association" "kwu_prd_vpc_rt_pub_assoc_bastion_2a" {
  subnet_id      = aws_subnet.kwu_prd_vpc_bastion_pub_2a.id
  route_table_id = aws_route_table.kwu_prd_vpc_rt_pub.id
}


# --- Private 라우팅 테이블 연결 ---

# TOMCAT 프라이빗 서브넷 2A 연결
resource "aws_route_table_association" "kwu_prd_vpc_rt_pri_assoc_tomcat_2a" {
  subnet_id      = aws_subnet.kwu_prd_vpc_tomcat_pri_2a.id
  route_table_id = aws_route_table.kwu_prd_vpc_rt_pri.id
}

# TOMCAT 프라이빗 서브넷 2C 연결 (2중화)
resource "aws_route_table_association" "kwu_prd_vpc_rt_pri_assoc_tomcat_2c" {
  subnet_id      = aws_subnet.kwu_prd_vpc_tomcat_pri_2c.id
  route_table_id = aws_route_table.kwu_prd_vpc_rt_pri.id
}


