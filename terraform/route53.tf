provider "aws" {
  region = var.aws_region
}

resource "aws_route53_zone" "new_hosted_zone" {
  name = var.DOMAIN_NAME
}

## 추후 HTTPS 인증서 처리를 위해 얻는 값
data "aws_acm_certificate" "issued" {
  domain   = var.DOMAIN_NAME
  statuses = ["ISSUED"]
}

resource "aws_route53_record" "external_dns" {
  zone_id        = aws_route53_zone.new_hosted_zone.zone_id
  name           = "api.${var.DOMAIN_NAME}"
  type           = "A"
  set_identifier = var.aws_region

  latency_routing_policy {
    region = var.aws_region
  }

  alias {
    name                   = aws_lb.record_lb.dns_name
    zone_id                = aws_lb.record_lb.zone_id
    evaluate_target_health = true
  }
}
