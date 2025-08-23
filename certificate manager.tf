resource "aws_acm_certificate" "cert" {
  provider = aws.disaster

  domain_name       = var.domain_name
  validation_method = "DNS"

  subject_alternative_names = [
    var.alt_domain_name
  ]
}

resource "aws_acm_certificate_validation" "cert-validation" {
  provider = aws.disaster

  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [for record in aws_route53_record.cert-record : record.fqdn]
}