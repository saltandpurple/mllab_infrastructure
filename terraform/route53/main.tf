resource "aws_route53_record" "cname_records" {
  for_each = var.cname_records

  name    = each.value.name
  type    = "CNAME"
  zone_id = var.zone_id
  ttl     = each.value.ttl
  records = each.value.records
}

