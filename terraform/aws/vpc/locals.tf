locals {
  default_private_routes = [
    {
      cidr_block = aws_vpc.main_vpc.cidr_block
      gateway_id = "local"
    }
  ]

  default_public_routes = [
    {
      cidr_block = aws_vpc.main_vpc.cidr_block
      gateway_id = "local"
    },
    {
      cidr_block = "0.0.0.0/0"
      gateway_id = aws_internet_gateway.main_igw.id
    }
  ]

  private_route_table_routes = concat(
    local.default_private_routes,
    var.private_route_table_routes
  )

  public_route_table_routes = concat(
    local.default_public_routes,
    var.public_route_table_routes
  )
}
