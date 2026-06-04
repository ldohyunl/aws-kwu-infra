# 이미 발급된 ACM 인증서 참조 (새로 생성하지 않음 → destroy해도 삭제 안 됨)
data "aws_acm_certificate" "main" {
  domain      = var.my_domain
  statuses    = ["ISSUED"]
  most_recent = true
}
