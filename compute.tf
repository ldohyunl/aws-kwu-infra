# EC2 인스턴스 5대 (고정 사설 IP 및 자동 설치 스크립트 포함)

#===========================================================
# Ubuntu 22.04 LTS AMI 자동 조회
#===========================================================
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical 공식 계정

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

#===========================================================
# BASTION Server (Public 2A, 10.250.4.240)
#===========================================================
resource "aws_instance" "kwu_prd_vpc_bastion_pub_2a" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = var.key_name
  subnet_id              = aws_subnet.kwu_prd_vpc_bastion_pub_2a.id
  vpc_security_group_ids = [aws_security_group.kwu_prd_vpc_bastion_pub_sg_2a.id]

  private_ip                  = "10.250.4.240"
  associate_public_ip_address = true

  tags = {
    Name = "KWU-PRD-VPC-BASTION-PUB-2A"
  }
}

#===========================================================
# NGINX Web Server 2A (Public 2A, 10.250.1.240) - 빨간 페이지
#===========================================================
resource "aws_instance" "kwu_prd_vpc_nginx_pub_2a" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = var.key_name
  subnet_id              = aws_subnet.kwu_prd_vpc_nginx_pub_2a.id
  vpc_security_group_ids = [aws_security_group.kwu_prd_vpc_nginx_pub_sg_2a.id]

  private_ip                  = "10.250.1.240"
  associate_public_ip_address = true

  user_data = <<-USERDATA
    #!/bin/bash
    set -e

    # 1. Nginx 공식 저장소 등록
    echo "deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] https://nginx.org/packages/ubuntu jammy nginx" > /etc/apt/sources.list.d/nginx.list
    echo "deb-src [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] https://nginx.org/packages/ubuntu jammy nginx" >> /etc/apt/sources.list.d/nginx.list

    # 2. GPG 키 추가
    curl -fsSL https://nginx.org/keys/nginx_signing.key | gpg --dearmor -o /usr/share/keyrings/nginx-archive-keyring.gpg

    # 3. 설치
    apt-get -y update
    apt-get -y install nginx net-tools

    # 4. 빨간 페이지 (2A 식별용)
    cat > /usr/share/nginx/html/index.html << 'HTML_EOF'
    <html>
    <head>
    <title>Amazon Nginx-2A Connected Success !!!</title>
    <style>body {margin-top: 40px; background-color: red;}</style>
    </head>
    <body>
    <div style="color:white;text-align:center">
    <h1>Amazon Nginx-2A Connected Success !!!</h1>
    <h2>Congratulations!</h2>
    <p><em>Your application is now running on a container in Amazon ECS.</em></p>
    </div>
    </body>
    </html>
    HTML_EOF

    # 5. Nginx 서비스 시작
    systemctl enable nginx
    systemctl start nginx
  USERDATA

  tags = {
    Name = "KWU-PRD-VPC-NGINX-PUB-2A"
  }
}

#===========================================================
# NGINX Web Server 2C (Public 2C, 10.250.11.240) - 파란 페이지
#===========================================================
resource "aws_instance" "kwu_prd_vpc_nginx_pub_2c" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = var.key_name
  subnet_id              = aws_subnet.kwu_prd_vpc_nginx_pub_2c.id
  vpc_security_group_ids = [aws_security_group.kwu_prd_vpc_nginx_pub_sg_2c.id]

  private_ip                  = "10.250.11.240"
  associate_public_ip_address = true

  user_data = <<-USERDATA
    #!/bin/bash
    set -e

    # 1. Nginx 공식 저장소 등록
    echo "deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] https://nginx.org/packages/ubuntu jammy nginx" > /etc/apt/sources.list.d/nginx.list
    echo "deb-src [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] https://nginx.org/packages/ubuntu jammy nginx" >> /etc/apt/sources.list.d/nginx.list

    # 2. GPG 키 추가
    curl -fsSL https://nginx.org/keys/nginx_signing.key | gpg --dearmor -o /usr/share/keyrings/nginx-archive-keyring.gpg

    # 3. 설치
    apt-get -y update
    apt-get -y install nginx net-tools

    # 4. 파란 페이지 (2C 식별용)
    cat > /usr/share/nginx/html/index.html << 'HTML_EOF'
    <html>
    <head>
    <title>Amazon Nginx-2C Connected Success !!!</title>
    <style>body {margin-top: 40px; background-color: blue;}</style>
    </head>
    <body>
    <div style="color:white;text-align:center">
    <h1>Amazon Nginx-2C Connected Success !!!</h1>
    <h2>Congratulations!</h2>
    <p><em>Your application is now running on a container in Amazon ECS.</em></p>
    </div>
    </body>
    </html>
    HTML_EOF

    # 5. Nginx 서비스 시작
    systemctl enable nginx
    systemctl start nginx
  USERDATA

  tags = {
    Name = "KWU-PRD-VPC-NGINX-PUB-2C"
  }
}

#===========================================================
# Tomcat WAS Server 2A (Private 2A, 10.250.2.240)
#===========================================================
resource "aws_instance" "kwu_prd_vpc_tomcat_pri_2a" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = var.key_name
  subnet_id              = aws_subnet.kwu_prd_vpc_tomcat_pri_2a.id
  vpc_security_group_ids = [aws_security_group.kwu_prd_vpc_tomcat_pri_sg_2a.id]

  private_ip                  = "10.250.2.240"
  associate_public_ip_address = false

  user_data = <<-USERDATA
    #!/bin/bash
    set -e

    # 1. JDK 11 설치
    apt-get -y update
    apt-get install -y openjdk-11-jdk

    # 2. JAVA_HOME 환경변수 영구 등록
    cat >> /etc/profile << 'PROFILE_EOF'
    export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
    export PATH=$PATH:$JAVA_HOME/bin
    export CLASSPATH=$JAVA_HOME/lib/tools.jar
    PROFILE_EOF

    export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64

    # 3. Tomcat 9.0.108 다운로드 및 설치
    cd /root
    wget -q https://archive.apache.org/dist/tomcat/tomcat-9/v9.0.108/bin/apache-tomcat-9.0.108.tar.gz

    groupadd tomcat
    mkdir -p /home/tomcat
    tar -xf apache-tomcat-9.0.108.tar.gz -C /home/tomcat/
    useradd -s /usr/sbin/nologin -g tomcat -d /home/tomcat tomcat

    # 4. systemd 서비스 등록
    cat > /etc/systemd/system/tomcat.service << 'SERVICE_EOF'
    [Unit]
    Description=Apache Tomcat 9.0 Web Application Container
    After=network.target

    [Service]
    Type=forking
    Environment=JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
    Environment=CATALINA_PID=/home/tomcat/apache-tomcat-9.0.108/temp/tomcat.pid
    Environment=CATALINA_HOME=/home/tomcat/apache-tomcat-9.0.108
    Environment=CATALINA_BASE=/home/tomcat/apache-tomcat-9.0.108
    Environment='CATALINA_OPTS=-Xms512M -Xmx1024M -server -XX:+UseParallelGC'
    Environment='JAVA_OPTS=-Djava.awt.headless=true -Djava.security.egd=file:/dev/./urandom'
    ExecStart=/home/tomcat/apache-tomcat-9.0.108/bin/startup.sh
    ExecStop=/home/tomcat/apache-tomcat-9.0.108/bin/shutdown.sh
    User=tomcat
    Group=tomcat
    UMask=0007
    RestartSec=10
    Restart=always

    [Install]
    WantedBy=multi-user.target
    SERVICE_EOF

    # 5. 권한 설정 및 서비스 시작
    chgrp -R tomcat /home/tomcat/
    chown -R tomcat /home/tomcat/
    chmod +x /home/tomcat/apache-tomcat-9.0.108/bin/*.sh
    systemctl daemon-reload
    systemctl enable tomcat.service
    systemctl start tomcat
  USERDATA

  tags = {
    Name = "KWU-PRD-VPC-TOMCAT-PRI-2A"
  }
}

#===========================================================
# Tomcat WAS Server 2C (Private 2C, 10.250.12.240)
#===========================================================
resource "aws_instance" "kwu_prd_vpc_tomcat_pri_2c" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = var.key_name
  subnet_id              = aws_subnet.kwu_prd_vpc_tomcat_pri_2c.id
  vpc_security_group_ids = [aws_security_group.kwu_prd_vpc_tomcat_pri_sg_2c.id]

  private_ip                  = "10.250.12.240"
  associate_public_ip_address = false

  user_data = <<-USERDATA
    #!/bin/bash
    set -e

    # 1. JDK 11 설치
    apt-get -y update
    apt-get install -y openjdk-11-jdk

    # 2. JAVA_HOME 환경변수 영구 등록
    cat >> /etc/profile << 'PROFILE_EOF'
    export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
    export PATH=$PATH:$JAVA_HOME/bin
    export CLASSPATH=$JAVA_HOME/lib/tools.jar
    PROFILE_EOF

    export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64

    # 3. Tomcat 9.0.108 다운로드 및 설치
    cd /root
    wget -q https://archive.apache.org/dist/tomcat/tomcat-9/v9.0.108/bin/apache-tomcat-9.0.108.tar.gz

    groupadd tomcat
    mkdir -p /home/tomcat
    tar -xf apache-tomcat-9.0.108.tar.gz -C /home/tomcat/
    useradd -s /usr/sbin/nologin -g tomcat -d /home/tomcat tomcat

    # 4. systemd 서비스 등록
    cat > /etc/systemd/system/tomcat.service << 'SERVICE_EOF'
    [Unit]
    Description=Apache Tomcat 9.0 Web Application Container
    After=network.target

    [Service]
    Type=forking
    Environment=JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
    Environment=CATALINA_PID=/home/tomcat/apache-tomcat-9.0.108/temp/tomcat.pid
    Environment=CATALINA_HOME=/home/tomcat/apache-tomcat-9.0.108
    Environment=CATALINA_BASE=/home/tomcat/apache-tomcat-9.0.108
    Environment='CATALINA_OPTS=-Xms512M -Xmx1024M -server -XX:+UseParallelGC'
    Environment='JAVA_OPTS=-Djava.awt.headless=true -Djava.security.egd=file:/dev/./urandom'
    ExecStart=/home/tomcat/apache-tomcat-9.0.108/bin/startup.sh
    ExecStop=/home/tomcat/apache-tomcat-9.0.108/bin/shutdown.sh
    User=tomcat
    Group=tomcat
    UMask=0007
    RestartSec=10
    Restart=always

    [Install]
    WantedBy=multi-user.target
    SERVICE_EOF

    # 5. 권한 설정 및 서비스 시작
    chgrp -R tomcat /home/tomcat/
    chown -R tomcat /home/tomcat/
    chmod +x /home/tomcat/apache-tomcat-9.0.108/bin/*.sh
    systemctl daemon-reload
    systemctl enable tomcat.service
    systemctl start tomcat
  USERDATA

  tags = {
    Name = "KWU-PRD-VPC-TOMCAT-PRI-2C"
  }
}
