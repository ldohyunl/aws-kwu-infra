# Route53 호스팅 존 및 DNS 레코드
# ※ 호스팅 존은 이미 생성되어 있다고 가정하고 데이터 소스로 참조합니다.

#===========================================================
# 기존 Route53 호스팅 존 조회 (신규 생성 X)
#===========================================================
data "aws_route53_zone" "main" {
  name         = var.my_domain
  private_zone = false
}

#===========================================================
# A 레코드: 루트 도메인 → ALB
#===========================================================
resource "aws_route53_record" "root" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = var.my_domain
  type    = "A"

  alias {
    name                   = aws_lb.kwu_prd_vpc_alb.dns_name
    zone_id                = aws_lb.kwu_prd_vpc_alb.zone_id
    evaluate_target_health = true
  }
}

#===========================================================
# A 레코드: www 서브도메인 → ALB
#===========================================================
resource "aws_route53_record" "www" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "www.${var.my_domain}"
  type    = "A"

  alias {
    name                   = aws_lb.kwu_prd_vpc_alb.dns_name
    zone_id                = aws_lb.kwu_prd_vpc_alb.zone_id
    evaluate_target_health = true
  }
}
