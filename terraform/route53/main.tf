locals {
  zone_id = "Z2P1EM28KT3JJI"
}

 resource "aws_route53_record" "acm_validation" {
  name    = "_16a8d05b235817a11d81bff11ad95f65.mllab.davidsfreun.de."
  type    = "CNAME"
  zone_id = local.zone_id
  ttl     = 300
  records = ["_24859c95caf07c7b1ec6800e67bfa379.xlfgrmvvlj.acm-validations.aws."]
}

resource "aws_route53_record" "wildcard" {
  name    = "*.mllab.davidsfreun.de"
  type    = "CNAME"
  zone_id = local.zone_id
  ttl     = 300
  records = ["nginx-ingress-mllab-9cbbb431c5057762.elb.eu-central-1.amazonaws.com"]
}

