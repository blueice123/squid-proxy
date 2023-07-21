resource "aws_route_table" "public" {
  depends_on = [aws_internet_gateway.igw] 
  lifecycle {
    # When attaching VPN gateways it is common to define aws_vpn_gateway_route_propagation
    # resources that manipulate the attributes of the routing table (typically for the private subnets)
    ignore_changes = [propagating_vgws]
    # ignore_changes = [route]
    # prevent_destroy = true
  }

  vpc_id = aws_vpc.vpc_main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  
  tags = {
    Name = format(
        "%s-%s-rt-pub",
        var.project_code,
        terraform.workspace
    )
  }
}

resource "aws_route_table" "squid_proxy_subnets" {
  depends_on = [aws_nat_gateway.nat_gw]
  lifecycle {
    # When attaching VPN gateways it is common to define aws_vpn_gateway_route_propagation
    # resources that manipulate the attributes of the routing table (typically for the private subnets)
    ignore_changes = [propagating_vgws]
    # ignore_changes = [route]
    # prevent_destroy = true
  }
  
  count = local.nat_gateway_count #length(aws_nat_gateway.nat_gw)

  vpc_id = aws_vpc.vpc_main.id
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw[count.index].id
  }
  
  tags = {
    Name = format(
        "%s-%s-rt-squid-%s",
        var.project_code,
        terraform.workspace,
        element(split("", local.squid_proxy_subnets[count.index].zone), length(local.squid_proxy_subnets[count.index].zone) - 1)
    )
  }
}

resource "aws_route_table" "private_subnets" {
#   depends_on = [aws_instance.squid_proxy]
  lifecycle {
    # When attaching VPN gateways it is common to define aws_vpn_gateway_route_propagation
    # resources that manipulate the attributes of the routing table (typically for the private subnets)
    # ignore_changes = [propagating_vgws]
    ignore_changes = [route]
    # prevent_destroy = true
  }

#   count = local.nat_gateway_count #length(aws_nat_gateway.nat_gw)

  vpc_id = aws_vpc.vpc_main.id
#   route {
#     cidr_block = "0.0.0.0/0"
#     nat_gateway_id = aws_nat_gateway.nat_gw[count.index].id
#   }
  
  tags = {
    Name = format(
        "%s-%s-rt-pri",
        var.project_code,
        terraform.workspace
    )
  }
}

