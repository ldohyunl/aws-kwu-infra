# terraform apply 완료 후 접속 정보 출력

output "bastion_public_ip" {
  description = "BASTION 서버 퍼블릭 IP (SSH 진입점)"
  value       = aws_instance.kwu_prd_vpc_bastion_pub_2a.public_ip
}

output "nginx_2a_public_ip" {
  description = "NGINX-2A 퍼블릭 IP (빨간 페이지)"
  value       = aws_instance.kwu_prd_vpc_nginx_pub_2a.public_ip
}

output "nginx_2c_public_ip" {
  description = "NGINX-2C 퍼블릭 IP (파란 페이지)"
  value       = aws_instance.kwu_prd_vpc_nginx_pub_2c.public_ip
}

output "clb_dns_name" {
  description = "CLB DNS 주소 (새로고침 시 빨강↔파랑 교차)"
  value       = "http://${aws_elb.kwu_prd_vpc_clb.dns_name}"
}

output "alb_dns_name" {
  description = "ALB DNS 주소"
  value       = "http://${aws_lb.kwu_prd_vpc_alb.dns_name}"
}

output "domain_http" {
  description = "도메인 HTTP 접속 주소"
  value       = "http://${var.my_domain}"
}

output "domain_https" {
  description = "도메인 HTTPS 접속 주소 (인증서 발급 완료 후 사용 가능)"
  value       = "https://${var.my_domain}"
}

output "route53_zone_id" {
  description = "Route53 호스팅 존 ID"
  value       = data.aws_route53_zone.main.zone_id
}
