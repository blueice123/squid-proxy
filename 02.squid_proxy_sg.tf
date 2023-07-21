resource "aws_security_group" "admin" {
    ingress {
        from_port   = 22
        to_port     = 22
        protocol    = "TCP"
        cidr_blocks = [var.vpc_cidr]
        description = "For SSH"
    }
    ingress {
        from_port   = 22
        to_port     = 22
        protocol    = "TCP"
        cidr_blocks = ["${chomp(data.http.icanhazip.body)}/32"]
        description = "For SSH"
    }
    egress {
        from_port   = 22
        to_port     = 22
        protocol    = "TCP"
        cidr_blocks = [var.vpc_cidr]
        description = "For SSH Traffic Outbound"
    }
    egress {
        from_port   = 3389
        to_port     = 3389
        protocol    = "TCP"
        cidr_blocks = [var.vpc_cidr]
        description = "For RDP Traffic Outbound"
    }

    vpc_id      = aws_vpc.vpc_main.id
    name        = format("%s-%s-admin-sg", var.project_code, terraform.workspace)
    description = format("%s-%s-admin-sg", var.project_code, terraform.workspace)
    
    tags = {
        Name = format("%s-%s-admin-sg", var.project_code, terraform.workspace)
    }
}


resource "aws_security_group" "squid" {
    ingress {
        from_port   = 80
        to_port     = 80
        protocol    = "TCP"
        cidr_blocks = [var.vpc_cidr]
        description = "For HTTP Traffic"
    }
    ingress {
        from_port   = 443
        to_port     = 443
        protocol    = "TCP"
        cidr_blocks = [var.vpc_cidr]
        description = "For HTTPS Traffic"
    }
    ingress {
        from_port   = 3128
        to_port     = 3130
        protocol    = "TCP"
        cidr_blocks = [var.vpc_cidr]
        description = "For squid proxy Traffic"
    }
    egress {
        from_port   = 80
        to_port     = 80
        protocol    = "TCP"
        cidr_blocks = ["0.0.0.0/0"]
        description = "For HTTP Traffic Outbound"
    }
    egress {
        from_port   = 443
        to_port     = 443
        protocol    = "TCP"
        cidr_blocks = ["0.0.0.0/0"]
        description = "For HTTPS Traffic Outbound"
    }
    egress {
        from_port   = 3128
        to_port     = 3130
        protocol    = "TCP"
        cidr_blocks = ["0.0.0.0/0"]
        description = "For squid proxy Traffic"
    }

    vpc_id      = aws_vpc.vpc_main.id
    name        = format("%s-%s-squid-sg", var.project_code, terraform.workspace)
    description = format("%s-%s-squid-sg", var.project_code, terraform.workspace)
    
    tags = {
        Name = format("%s-%s-squid-sg", var.project_code, terraform.workspace)
    }
}

