resource "aws_acm_certificate" "certificate" {
  domain_name               = var.domain_name
  subject_alternative_names = var.alternate_domain_names
  validation_method         = "DNS"

  tags = local.merged_tags

  options {
    certificate_transparency_logging_preference = var.enable_certificate_transparency_log ? "ENABLED" : "DISABLED"
  }
}

resource "aws_route53_record" "validation" {
  count = length([var.domain_name, var.alternate_domain_names])

  zone_id = var.route53_zone_id
  name    = aws_acm_certificate.certificate.domain_validation_options[count.index].resource_record_name
  type    = aws_acm_certificate.certificate.domain_validation_options[count.index].resource_record_type
  ttl     = 60

  records = [
    aws_acm_certificate.certificate.domain_validation_options[count.index].resource_record_value
  ]

  allow_overwrite = true // NOTE: this is required for Certificate Validation

  depends_on = [
    aws_acm_certificate.certificate
  ]
}

resource "aws_acm_certificate_validation" "validation" {
  count = length(aws_route53_record.validation)

  certificate_arn         = aws_acm_certificate.certificate.arn
  validation_record_fqdns = aws_route53_record.validation.*.fqdn

  timeouts {
    create = "60m"
  }
}