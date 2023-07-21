resource "aws_vpc" "vpc_main" {
  cidr_block = var.vpc_cidr
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support
  assign_generated_ipv6_cidr_block = var.assign_generated_ipv6_cidr_block
  instance_tenancy = var.instance_tenancy
  tags = {
      Name = format(
        "%s-%s-vpc",
        var.project_code,
        terraform.workspace
      )
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc_main.id
  tags = {
      Name = format(
        "%s-%s-igw",
        var.project_code,
        terraform.workspace
      )
  }
}
resource "aws_eip" "eip_for_nat" {
  depends_on = [aws_route_table.public] 
  count = local.nat_gateway_count 
  tags = {
    Name = format(
      "%s-%s-nat-%s",
      var.project_code,
      terraform.workspace,
      element(split("", local.public_subnets[count.index].zone), length(local.public_subnets[count.index].zone) - 1)
    )
  }
}
resource "aws_nat_gateway" "nat_gw" {
  depends_on = [aws_eip.eip_for_nat] 
  count = local.nat_gateway_count
  allocation_id = aws_eip.eip_for_nat[count.index].id
  subnet_id = aws_subnet.public[count.index].id
  tags = {
     Name = format(
         "%s-%s-nat-%s",
         var.project_code,
         terraform.workspace,
         element(split("", local.public_subnets[count.index].zone), length(local.public_subnets[count.index].zone) - 1)
     )
   }
}
resource "aws_subnet" "public" {
  count             = length(local.public_subnets)
  vpc_id            = aws_vpc.vpc_main.id
  cidr_block        = local.public_subnets[count.index].cidr
  availability_zone = local.public_subnets[count.index].zone
  tags = {
     Name = format(
         "%s-%s-%s-%s",
         var.project_code,
         terraform.workspace,
         local.public_subnets[count.index].purpose,
         element(split("", local.public_subnets[count.index].zone), length(local.public_subnets[count.index].zone) - 1)
     )
   }
}
resource "aws_route_table_association" "public" {
  count = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}


resource "aws_subnet" "private_subnets" {
  count             = length(local.private_subnets)
  vpc_id            = aws_vpc.vpc_main.id
  cidr_block        = local.private_subnets[count.index].cidr
  availability_zone = local.private_subnets[count.index].zone
  tags = {
     Name = format(
         "%s-%s-%s-%s",
         var.project_code,
         terraform.workspace,
         local.private_subnets[count.index].purpose,
         element(split("", local.private_subnets[count.index].zone), length(local.private_subnets[count.index].zone) - 1)
     )
   }
}
resource "aws_route_table_association" "private_subnets" {
  count = length(aws_subnet.private_subnets)
  subnet_id      = aws_subnet.private_subnets[count.index].id
  route_table_id  = element(
    aws_route_table.private_subnets.*.id,
    var.single_nat == true ? 1 : local.zone_index[element(split("", local.private_subnets[count.index].zone), length(local.private_subnets[count.index].zone) - 1)]
  )
}


resource "aws_subnet" "squid_proxy_subnets" {
  count             = length(local.squid_proxy_subnets)
  vpc_id            = aws_vpc.vpc_main.id
  cidr_block        = local.squid_proxy_subnets[count.index].cidr
  availability_zone = local.squid_proxy_subnets[count.index].zone
  tags = {
     Name = format(
         "%s-%s-%s-%s",
         var.project_code,
         terraform.workspace,
         local.squid_proxy_subnets[count.index].purpose,
         element(split("", local.squid_proxy_subnets[count.index].zone), length(local.squid_proxy_subnets[count.index].zone) - 1)
     )
   }
}
resource "aws_route_table_association" "vpcsquid_proxy_subnets_transit" {
  count = length(aws_subnet.squid_proxy_subnets)
  subnet_id      = aws_subnet.squid_proxy_subnets[count.index].id
  route_table_id  = element(
    aws_route_table.squid_proxy_subnets.*.id,
    var.single_nat == true ? 1 : local.zone_index[element(split("", local.squid_proxy_subnets[count.index].zone), length(local.squid_proxy_subnets[count.index].zone) - 1)]
  )
}
