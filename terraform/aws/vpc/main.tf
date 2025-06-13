# VPC
resource "aws_vpc" "main_vpc" {
  cidr_block = var.vpc_primary_cidr

  tags = {
    Name = var.name
  }
}

# Subnets
resource "aws_subnet" "public_subnet" {
  count                   = 3
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[count.index]

  tags = merge(var.public_subnet_tags, { Name = "PublicSubnet-${element(data.aws_availability_zones.available.names, count.index)}" })
}

resource "aws_subnet" "private_subnet" {
  count                   = 3
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = var.private_subnet_cidrs[count.index]
  map_public_ip_on_launch = false
  availability_zone       = data.aws_availability_zones.available.names[count.index]

  tags = merge(var.private_subnet_tags, { Name = "PrivateSubnet-${element(data.aws_availability_zones.available.names, count.index)}" })
}


### ROUTING
resource "aws_internet_gateway" "main_igw" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "PrimaryVPCIGW"
  }
}

resource "aws_vpc_endpoint" "s3_endpoint" {
  vpc_id = aws_vpc.main_vpc.id

  service_name = "com.amazonaws.eu-central-1.s3"

  route_table_ids = [aws_route_table.private_routing_table.id, aws_route_table.public_routing_table.id]

  tags = {
    Name = "S3Endpoint"
  }
}

resource "aws_vpc_endpoint" "dynamodb_endpoint" {
  vpc_id = aws_vpc.main_vpc.id

  service_name = "com.amazonaws.eu-central-1.dynamodb"

  route_table_ids = [aws_route_table.private_routing_table.id, aws_route_table.public_routing_table.id]

  tags = {
    Name = "DynamoDBEndpoint"
  }
}

resource "aws_route_table" "private_routing_table" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = aws_vpc.main_vpc.cidr_block
    gateway_id = "local"
  }

  dynamic "route" {
    for_each = local.private_route_table_routes
    content {
      cidr_block = route.value.cidr_block

      egress_only_gateway_id    = lookup(route.value, "egress_only_gateway_id", null)
      gateway_id                = lookup(route.value, "gateway_id", null)
      nat_gateway_id            = lookup(route.value, "nat_gateway_id", null)
      network_interface_id      = lookup(route.value, "network_interface_id", null)
      transit_gateway_id        = lookup(route.value, "transit_gateway_id", null)
      vpc_endpoint_id           = lookup(route.value, "vpc_endpoint_id", null)
      vpc_peering_connection_id = lookup(route.value, "vpc_peering_connection_id", null)
    }
  }

  tags = {
    Name = "PrivateRoutingTable"
  }
}

resource "aws_route_table" "public_routing_table" {
  vpc_id = aws_vpc.main_vpc.id

  dynamic "route" {
    for_each = local.public_route_table_routes
    content {
      cidr_block = route.value.cidr_block

      egress_only_gateway_id    = lookup(route.value, "egress_only_gateway_id", null)
      gateway_id                = lookup(route.value, "gateway_id", null)
      nat_gateway_id            = lookup(route.value, "nat_gateway_id", null)
      network_interface_id      = lookup(route.value, "network_interface_id", null)
      transit_gateway_id        = lookup(route.value, "transit_gateway_id", null)
      vpc_endpoint_id           = lookup(route.value, "vpc_endpoint_id", null)
      vpc_peering_connection_id = lookup(route.value, "vpc_peering_connection_id", null)
    }
  }

  tags = {
    Name = "PublicRoutingTable"
  }
}

resource "aws_route_table_association" "public_subnet_association" {
  count = length(aws_subnet.public_subnet.*.id)

  subnet_id      = aws_subnet.public_subnet[count.index].id
  route_table_id = aws_route_table.public_routing_table.id
}

resource "aws_route_table_association" "private_subnet_association" {
  count = length(aws_subnet.private_subnet.*.id)

  subnet_id      = aws_subnet.private_subnet[count.index].id
  route_table_id = aws_route_table.private_routing_table.id
}
