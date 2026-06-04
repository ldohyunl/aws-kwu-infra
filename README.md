# KWU AWS 인프라 자동 구축

수업 실습 환경(02~08 과정)을 `bash setup.sh` 한 번으로 자동 구축하는 Terraform 스크립트.

---

## 아키텍처

```
[인터넷]
    │
    ├─ BASTION (10.250.4.240) ── SSH 진입점
    │
    ├─ CLB ─┐
    └─ ALB ─┤── NGINX-2A (10.250.1.240) - 빨간 페이지
             └── NGINX-2C (10.250.11.240) - 파란 페이지

Route53: 도메인 → ALB
ACM: HTTPS 인증서 (기존 인증서 참조)

[Private]
    TOMCAT-2A (10.250.2.240) ← JDK11 + Tomcat 9.0.108
    TOMCAT-2C (10.250.12.240) ← JDK11 + Tomcat 9.0.108
```

### 생성 리소스 목록

| 종류 | 이름 |
|------|------|
| VPC | KWU-PRD-VPC (10.250.0.0/16) |
| 서브넷 | NGINX-PUB-2A/2C, BASTION-PUB-2A, TOMCAT-PRI-2A/2C |
| 보안그룹 | BASTION, NGINX×2, TOMCAT×2, CLB, ALB |
| EC2 | BASTION, NGINX-2A/2C, TOMCAT-2A/2C (Ubuntu 22.04, t3.micro) |
| 로드밸런서 | CLB (HTTP 80), ALB (HTTP 80 / HTTPS 443) |
| Route53 | A 레코드 (루트, www) → ALB |
| ACM | 기존 인증서 참조 (삭제 안 됨) |

---

## 사전 조건

AWS 계정에 아래 세 가지가 미리 있어야 함 (수업 때 생성한 것)

- [ ] 키페어 `kwuaws`
- [ ] Route53 호스팅 존 (본인 도메인)
- [ ] ACM 인증서 발급 완료

---

## 사용법

### 구축
```bash
git clone https://github.com/ldohyunl/aws-kwu-infra.git
cd aws-kwu-infra && bash setup.sh
```

실행하면 도메인 이름만 입력하면 됨. 나머지는 자동.

```
[1/4] Terraform 설치       ← 자동
[2/4] 도메인 입력          ← 직접 입력 (유일한 수동 작업)
[3/4] Terraform 초기화     ← 자동
[4/4] 인프라 구축 (3~4분)  ← 자동
```

완료 후 접속 링크 자동 출력:

```
  🌐 접속 링크
  HTTPS (도메인)  : https://본인도메인.com
  CLB (로드밸런서): http://KWU-PRD-VPC-CLB-xxx.elb.amazonaws.com
  NGINX-2A (빨강) : http://1.2.3.4
  NGINX-2C (파랑) : http://5.6.7.8

  🔑 SSH 접속
  BASTION : ssh -i kwuaws.pem ubuntu@9.10.11.12

  🗑️  환경 삭제
  bash cleanup.sh
```

### 삭제
```bash
bash cleanup.sh
```
AWS 리소스 삭제 + CloudShell 저장공간 정리까지 한 번에.

---

## 파일 구조

```
aws-kwu-infra/
├── setup.sh                  # 구축 실행 스크립트
├── cleanup.sh                # 삭제 실행 스크립트
├── provider.tf               # AWS provider (ap-northeast-2, v5.80)
├── variables.tf              # 변수 (key_name, my_domain 등)
├── network.tf                # VPC, 서브넷, IGW, NAT GW, 라우팅
├── security.tf               # 보안그룹 7개
├── compute.tf                # EC2 5대 + user_data 자동 설치
├── loadbalancer.tf           # CLB, ALB, Target Group
├── acm.tf                    # 기존 ACM 인증서 참조
├── route53.tf                # 기존 호스팅 존 참조 + A 레코드
├── outputs.tf                # 접속 정보 출력
├── terraform.tfvars.example  # 변수 예시 파일
└── aws/                      # 수업 실습 가이드 (02~08)
```

---

## 주의사항

- **CloudShell 저장공간**: 974MB 제한. `cleanup.sh` 실행 시 자동 정리됨.
- **삭제되지 않는 것**: ACM 인증서, Route53 호스팅 존, 키페어 (수업 자산이므로 유지)
- **CLB ENI 경고**: `cleanup.sh` 실행 시 Warning이 뜰 수 있으나 정상 삭제됨. 무시해도 됨.
