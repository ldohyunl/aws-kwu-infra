#!/bin/bash
set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}"
echo "========================================"
echo "   KWU AWS 인프라 자동 구축 스크립트   "
echo "========================================"
echo -e "${NC}"

# ─────────────────────────────────────────
# 1. Terraform 설치
# ─────────────────────────────────────────
echo -e "${YELLOW}[1/4] Terraform 확인 중...${NC}"

if ! command -v terraform &> /dev/null; then
    TERRAFORM_VERSION="1.9.5"
    echo "    Terraform ${TERRAFORM_VERSION} 설치 중..."

    wget -q "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip" -O /tmp/terraform.zip
    unzip -q /tmp/terraform.zip -d /tmp/
    mkdir -p "$HOME/bin"
    mv /tmp/terraform "$HOME/bin/terraform"
    export PATH="$PATH:$HOME/bin"
    rm /tmp/terraform.zip

    echo -e "    ${GREEN}✓ Terraform 설치 완료${NC}"
else
    echo -e "    ${GREEN}✓ Terraform 이미 설치됨${NC}"
fi

# ─────────────────────────────────────────
# 2. 사용자 입력
# ─────────────────────────────────────────
echo -e "\n${YELLOW}[2/4] 환경 설정${NC}"

read -p "    도메인 이름 입력 (예: mysite.store): " MY_DOMAIN
if [ -z "$MY_DOMAIN" ]; then
    echo -e "    ${RED}오류: 도메인을 입력해야 합니다.${NC}"
    exit 1
fi

read -p "    키페어 이름 입력 [kwuaws]: " KEY_NAME
KEY_NAME="${KEY_NAME:-kwuaws}"

cat > terraform.tfvars << EOF
aws_region    = "ap-northeast-2"
key_name      = "$KEY_NAME"
my_domain     = "$MY_DOMAIN"
instance_type = "t3.micro"
EOF

echo -e "    ${GREEN}✓ 설정 완료 (도메인: ${MY_DOMAIN}, 키페어: ${KEY_NAME})${NC}"

# ─────────────────────────────────────────
# 3. Terraform 초기화
# ─────────────────────────────────────────
echo -e "\n${YELLOW}[3/4] Terraform 초기화 중...${NC}"
terraform init -input=false -no-color
echo -e "    ${GREEN}✓ 초기화 완료${NC}"

# ─────────────────────────────────────────
# 4. 인프라 구축
# ─────────────────────────────────────────
echo -e "\n${YELLOW}[4/4] 인프라 구축 시작 (약 5~10분 소요)...${NC}"
echo "    ACM 인증서 발급 대기 중에 멈춘 것처럼 보일 수 있습니다. 정상입니다."
echo ""
terraform apply -auto-approve -input=false

# ─────────────────────────────────────────
# 완료
# ─────────────────────────────────────────
echo -e "\n${GREEN}"
echo "========================================"
echo "           구축 완료!"
echo "========================================"
echo -e "${NC}"
echo "접속 정보는 위 outputs 를 확인하세요."
echo ""
echo "환경 삭제할 때는:"
echo "  terraform destroy -auto-approve"
