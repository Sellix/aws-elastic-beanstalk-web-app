resource "aws_vpc" "sellix-eb-vpc" {
  cidr_block           = var.main_cidr_block
  instance_tenancy     = "default"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = merge({
    "Name" = "${var.tags["Project"]}-vpc"
    },
    var.tags
  )
}

resource "aws_eip" "sellix-eb-eip" {
  count = var.is_production ? length(local.availability_zones) : 0
  vpc   = "true"
  tags = merge({
    "Name" = "${var.tags["Project"]}-eip-${element(local.availability_zones, count.index)}"
    },
    var.tags
  )
  lifecycle {
    create_before_destroy = "true"
  }
}

resource "aws_subnet" "sellix-eb-public-subnet" {
  count             = var.is_production ? length(local.availability_zones) : 1
  vpc_id            = aws_vpc.sellix-eb-vpc.id
  availability_zone = element(local.availability_zones, count.index)
  cidr_block = cidrsubnet(
    var.main_cidr_block,
    8,
    count.index
  )
  map_public_ip_on_launch = true
  tags = merge({
    "Name" = "${var.tags["Project"]}-public-subnet-${element(local.availability_zones, count.index)}"
    },
    var.tags
  )
}

resource "aws_subnet" "sellix-eb-private-subnet" {
  count             = var.is_production ? length(local.availability_zones) : 0
  vpc_id            = aws_vpc.sellix-eb-vpc.id
  availability_zone = element(local.availability_zones, count.index)
  cidr_block = cidrsubnet(
    var.main_cidr_block,
    8,
    length(local.availability_zones) + count.index
  )
  map_public_ip_on_launch = false
  tags = merge({
    "Name" = "${var.tags["Project"]}-private-subnet-${element(local.availability_zones, count.index)}"
    },
    var.tags
  )
}

resource "aws_nat_gateway" "sellix-eb-nat-gateway" {
  count         = (var.is_production && !var.is_nat_instance) ? length(local.availability_zones) : 0
  allocation_id = element(aws_eip.sellix-eb-eip[*].id, count.index)
  subnet_id     = element(aws_subnet.sellix-eb-public-subnet[*].id, count.index)
  tags = merge({
    "Name" = "${var.tags["Project"]}-nat-gateway-${element(local.availability_zones, count.index)}"
    },
    var.tags
  )
  lifecycle {
    create_before_destroy = "true"
  }
}

resource "aws_network_interface" "fuck-nat-if" {
  count             = (var.is_production && var.is_nat_instance) ? length(local.availability_zones) : 0
  subnet_id         = aws_subnet.sellix-eb-public-subnet[count.index].id
  security_groups   = [one(aws_security_group.sellix-eb-fuck-nat-security-group).id]
  source_dest_check = false
}


resource "aws_instance" "fuck-nat" {
  count             = length(aws_network_interface.fuck-nat-if)
  availability_zone = element(local.availability_zones, count.index)
  ami               = "ami-044fc100ae64a0544"
  instance_type     = "t4g.nano"

  metadata_options {
    http_endpoint = "disabled" // not needed
    http_tokens   = "required"
  }

  network_interface {
    network_interface_id = aws_network_interface.fuck-nat-if[count.index].id
    device_index         = 0
  }

  tags = merge({
    "Name" = "${var.tags["Project"]}-fuck-nat-${element(local.availability_zones, count.index)}"
    },
    var.tags
  )

  lifecycle {
    create_before_destroy = "true"
  }
}

resource "aws_eip_association" "sellix-eb-eip-assoc" {
  count         = length(aws_instance.fuck-nat)
  instance_id   = aws_instance.fuck-nat[count.index].id
  allocation_id = aws_eip.sellix-eb-eip[count.index].id
}

resource "aws_internet_gateway" "sellix-eb-internet-gateway" {
  vpc_id = aws_vpc.sellix-eb-vpc.id
  tags = merge({
    "Name" = "${var.tags["Project"]}-internet-gateway"
    },
    var.tags
  )
}

resource "aws_route_table" "sellix-eb-public-route-table" {
  vpc_id = aws_vpc.sellix-eb-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.sellix-eb-internet-gateway.id
  }
  tags = merge({
    "Name" = "${var.tags["Project"]}-public-route-table"
    },
    var.tags
  )
}

resource "aws_route_table" "sellix-eb-private-route-table" {
  count  = var.is_production ? length(local.availability_zones) : 0
  vpc_id = aws_vpc.sellix-eb-vpc.id
  route {
    cidr_block           = "0.0.0.0/0"
    nat_gateway_id       = length(aws_nat_gateway.sellix-eb-nat-gateway) > 0 ? aws_nat_gateway.sellix-eb-nat-gateway[count.index].id : null
    network_interface_id = length(aws_instance.fuck-nat) > 0 ? aws_instance.fuck-nat[count.index].primary_network_interface_id : null
  }
  dynamic "route" { // peering with backend
    for_each = (var.is_production && local.is_peering) ? [1] : []
    content {
      cidr_block                = var.legacy-vpc-cidr-block
      vpc_peering_connection_id = var.legacy-peering-conn-id
    }
  }
  lifecycle {
    create_before_destroy = "true"
  }
  tags = merge({
    "Name" = "${var.tags["Project"]}-private-route-table-${element(local.availability_zones, count.index)}"
    },
    var.tags
  )
}

resource "aws_route" "sellix-eb-route" {
  route_table_id         = aws_route_table.sellix-eb-public-route-table.id
  gateway_id             = aws_internet_gateway.sellix-eb-internet-gateway.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route_table_association" "sellix-eb-public-route-table-association" {
  count          = var.is_production ? length(local.availability_zones) : 1
  subnet_id      = element(aws_subnet.sellix-eb-public-subnet[*].id, count.index)
  route_table_id = aws_route_table.sellix-eb-public-route-table.id
}

resource "aws_route_table_association" "sellix-eb-private-route-table-association" {
  count          = var.is_production ? length(local.availability_zones) : 0
  subnet_id      = element(aws_subnet.sellix-eb-private-subnet[*].id, count.index)
  route_table_id = var.is_production ? element(aws_route_table.sellix-eb-private-route-table[*].id, count.index) : aws_route_table.sellix-eb-private-route-table[0].id
}
