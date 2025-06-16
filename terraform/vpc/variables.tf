variable "name" {
  type        = string
  description = "Name of the VPC"
}

variable "vpc_primary_cidr" {
  type        = string
  description = "CIDR block for the VPC"
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "List of CIDR blocks for the public subnets"
}

variable "private_subnet_cidrs" {
  type        = list(string)
  description = "List of CIDR blocks for the private subnets"
}


variable "public_route_table_routes" {
  description = <<EOF
  (Optional) Configuration block of routes for the public route table.
  Values should be look like this:
  ```
  public_route_table_routes = [
    {
      cidr_block = "0.0.0.0/0"
      transit_gateway_id = "tgw-0123456789"
    }
  ]
  ```
  EOF
  type        = list(map(string))
  default     = []
}

variable "private_route_table_routes" {
  description = <<EOF
  (Optional) Configuration block of routes for the private route table.
  Values should be look like this:
  ```
  public_route_table_routes = [
    {
      cidr_block = "0.0.0.0/0"
      transit_gateway_id = "tgw-0123456789"
    }
  ]
  ```
  EOF
  type        = list(map(string))
  default     = []
}

variable "public_subnet_tags" {
  description = "(Optional) Additional tags for public subnet"
  type        = map(string)
  default     = {}
}

variable "private_subnet_tags" {
  description = "(Optional) Additional tags for private subnet"
  type        = map(string)
  default     = {}
}

