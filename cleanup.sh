#!/bin/bash
set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}"
echo "========================================"
echo "   KWU AWS 인프라 삭제 스크립트        "
echo "========================================"
echo -e "${NC}"

echo -e "${YELLOW}[1/2] AWS 리소스 삭제 중... (약 3~5분 소요)${NC}"
terraform destroy -auto-approve -input=false

echo -e "${YELLOW}[2/2] CloudShell 저장공간 정리 중...${NC}"
cd ~
rm -rf aws-kwu-infra

echo -e "${GREEN}"
echo "========================================"
echo "   삭제 완료! 모든 리소스가 제거됐습니다."
echo "========================================"
echo -e "${NC}"
