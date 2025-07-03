variable "zone_id" {
  description = "Route53 Zone ID"
  type        = string
  sensitive   = true
}

variable "cname_records" {
  description = "Map of CNAME records to create"
  type = map(object({
    name    = string
    records = list(string)
    ttl     = number
  }))
}