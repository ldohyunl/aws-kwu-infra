# ACM SSL/TLS 인증서 (DNS 검증 - Route53 자동 연동)

resource "aws_acm_certificate" "main" {
  domain_name               = var.my_domain
  subject_alternative_names = ["*.${var.my_domain}"]
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "KWU-ACM-${var.my_domain}"
  }
}

# Route53에 ACM DNS 검증용 CNAME 레코드 자동 생성
resource "aws_route53_record" "acm_validation" {
  for_each = {
    for dvo in aws_acm_certificate.main.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.main.zone_id
}

# 인증서 발급 완료 대기 (최대 5~10분 소요)
resource "aws_acm_certificate_validation" "main" {
  certificate_arn         = aws_acm_certificate.main.arn
  validation_record_fqdns = [for record in aws_route53_record.acm_validation : record.fqdn]
}
