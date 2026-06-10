#!/bin/bash
set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

REGION="ap-northeast-2"
KEYWORD="KWU"

echo -e "${YELLOW}"
echo "========================================"
echo "   KWU AWS 인프라 삭제 스크립트        "
echo "========================================"
echo -e "${NC}"

# -------------------------------------------------------
# [1/3] Terraform 관리 리소스 삭제
# -------------------------------------------------------
echo -e "${YELLOW}[1/3] Terraform 리소스 삭제 중... (약 3~5분 소요)${NC}"
terraform destroy -auto-approve -input=false

# -------------------------------------------------------
# [2/3] 수동 생성된 KWU 리소스 삭제 (AWS CLI)
#   삭제 순서: EC2 → ALB/CLB → Target Group → Security Group
#              → Subnet → Route Table → IGW → VPC
#   제외: Key Pair, Hosted Zone, ACM 인증서
# -------------------------------------------------------
echo -e "${YELLOW}[2/3] 수동 생성된 KWU 리소스 정리 중...${NC}"

## EC2 인스턴스
echo "  → EC2 인스턴스 확인 중..."
INSTANCE_IDS=$(aws ec2 describe-instances \
  --region "$REGION" \
  --filters "Name=tag:Name,Values=*${KEYWORD}*" "Name=instance-state-name,Values=pending,running,stopping,stopped" \
  --query "Reservations[].Instances[].InstanceId" \
  --output text)

if [ -n "$INSTANCE_IDS" ]; then
  echo "  → EC2 종료: $INSTANCE_IDS"
  aws ec2 terminate-instances --region "$REGION" --instance-ids $INSTANCE_IDS > /dev/null
  echo "  → EC2 종료 대기 중 (최대 3분)..."
  aws ec2 wait instance-terminated --region "$REGION" --instance-ids $INSTANCE_IDS
  echo "  → EC2 종료 완료"
else
  echo "  → 삭제할 EC2 없음"
fi

## ALB / CLB (이름에 KWU 포함)
echo "  → ALB 확인 중..."
ALB_ARNS=$(aws elbv2 describe-load-balancers \
  --region "$REGION" \
  --query "LoadBalancers[?contains(LoadBalancerName, '${KEYWORD}')].LoadBalancerArn" \
  --output text)

for ARN in $ALB_ARNS; do
  echo "  → ALB 삭제: $ARN"
  aws elbv2 delete-load-balancer --region "$REGION" --load-balancer-arn "$ARN"
done

if [ -n "$ALB_ARNS" ]; then
  echo "  → ALB 삭제 대기 중..."
  sleep 15
fi

## Classic LB (이름에 KWU 포함)
CLB_NAMES=$(aws elb describe-load-balancers \
  --region "$REGION" \
  --query "LoadBalancerDescriptions[?contains(LoadBalancerName, '${KEYWORD}')].LoadBalancerName" \
  --output text 2>/dev/null || true)

for NAME in $CLB_NAMES; do
  echo "  → CLB 삭제: $NAME"
  aws elb delete-load-balancer --region "$REGION" --load-balancer-name "$NAME"
done

## Target Group (이름에 KWU 포함)
echo "  → Target Group 확인 중..."
TG_ARNS=$(aws elbv2 describe-target-groups \
  --region "$REGION" \
  --query "TargetGroups[?contains(TargetGroupName, '${KEYWORD}')].TargetGroupArn" \
  --output text)

for ARN in $TG_ARNS; do
  echo "  → Target Group 삭제: $ARN"
  aws elbv2 delete-target-group --region "$REGION" --target-group-arn "$ARN" || true
done

## Security Group (이름에 KWU 포함, default 제외)
echo "  → Security Group 확인 중..."
SG_IDS=$(aws ec2 describe-security-groups \
  --region "$REGION" \
  --filters "Name=group-name,Values=*${KEYWORD}*" \
  --query "SecurityGroups[].GroupId" \
  --output text)

for SG in $SG_IDS; do
  echo "  → Security Group 삭제: $SG"
  aws ec2 delete-security-group --region "$REGION" --group-id "$SG" || true
done

## KWU VPC 목록 먼저 수집 (이후 단계에서 사용)
VPC_IDS=$(aws ec2 describe-vpcs \
  --region "$REGION" \
  --filters "Name=tag:Name,Values=*${KEYWORD}*" \
  --query "Vpcs[].VpcId" \
  --output text)

## Subnet (KWU 태그)
echo "  → Subnet 확인 중..."
SUBNET_IDS=$(aws ec2 describe-subnets \
  --region "$REGION" \
  --filters "Name=tag:Name,Values=*${KEYWORD}*" \
  --query "Subnets[].SubnetId" \
  --output text)

for SUBNET in $SUBNET_IDS; do
  echo "  → Subnet 삭제: $SUBNET"
  aws ec2 delete-subnet --region "$REGION" --subnet-id "$SUBNET" || true
done

## Route Table (KWU 태그, main 제외)
echo "  → Route Table 확인 중..."
RT_IDS=$(aws ec2 describe-route-tables \
  --region "$REGION" \
  --filters "Name=tag:Name,Values=*${KEYWORD}*" \
  --query "RouteTables[?Associations[?Main==\`false\`] || !Associations].RouteTableId" \
  --output text)

for RT in $RT_IDS; do
  # association 해제 후 삭제
  ASSOC_IDS=$(aws ec2 describe-route-tables \
    --region "$REGION" \
    --route-table-ids "$RT" \
    --query "RouteTables[].Associations[?Main==\`false\`].RouteTableAssociationId" \
    --output text 2>/dev/null || true)
  for ASSOC in $ASSOC_IDS; do
    aws ec2 disassociate-route-table --region "$REGION" --association-id "$ASSOC" || true
  done
  echo "  → Route Table 삭제: $RT"
  aws ec2 delete-route-table --region "$REGION" --route-table-id "$RT" || true
done

## Internet Gateway (KWU VPC에 attached)
echo "  → Internet Gateway 확인 중..."
for VPC in $VPC_IDS; do
  IGW_IDS=$(aws ec2 describe-internet-gateways \
    --region "$REGION" \
    --filters "Name=attachment.vpc-id,Values=$VPC" \
    --query "InternetGateways[].InternetGatewayId" \
    --output text)
  for IGW in $IGW_IDS; do
    echo "  → IGW detach 및 삭제: $IGW"
    aws ec2 detach-internet-gateway --region "$REGION" --internet-gateway-id "$IGW" --vpc-id "$VPC" || true
    aws ec2 delete-internet-gateway --region "$REGION" --internet-gateway-id "$IGW" || true
  done
done

## VPC (KWU 태그)
echo "  → VPC 확인 중..."
for VPC in $VPC_IDS; do
  echo "  → VPC 삭제: $VPC"
  aws ec2 delete-vpc --region "$REGION" --vpc-id "$VPC" || true
done

echo -e "${GREEN}  → 수동 생성 KWU 리소스 정리 완료${NC}"

# -------------------------------------------------------
# [3/3] CloudShell 저장공간 정리
# -------------------------------------------------------
echo -e "${YELLOW}[3/3] CloudShell 저장공간 정리 중...${NC}"
cd ~
rm -rf aws-kwu-infra

echo -e "${GREEN}"
echo "========================================"
echo "   삭제 완료! 모든 KWU 리소스가 제거됐습니다."
echo "   (Key Pair / Hosted Zone / ACM 인증서는 유지)"
echo "========================================"
echo -e "${NC}"
