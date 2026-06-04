# 친구들 각자의 도메인이나 키 명칭을 바꿀 수 있는 변수 방

variable "aws_region" {
  default     = "ap-northeast-2"
  description = "AWS 리전 (기본값: 서울)"
}

variable "key_name" {
  default     = "kwuaws" # 각자 AWS에 등록한 키 페어 이름
  description = "EC2 Key pair name (반드시 사전에 생성되어 있어야 함)"
}

variable "my_domain" {
  default     = "5tipe.store" # 각자 가비아에서 산 도메인
  description = "Route53 호스팅 존 및 ACM 인증서에 사용할 도메인"
}

variable "instance_type" {
  default     = "t3.micro"
  description = "EC2 인스턴스 유형"
}
