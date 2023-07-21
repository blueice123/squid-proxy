locals{ ## workspace 별로 배포되는 AWS 계정을 여러개로 분리, 이는 provider 에서 정의 됨
    dev  = "${terraform.workspace == "dev" ? "1111111111111": ""}"
    qa   = "${terraform.workspace == "qa" ? "1111111111111": ""}"
    prod = "${terraform.workspace == "prod" ? "239234376445": ""}" 
    account_num    = "${coalesce(local.dev, local.qa, local.prod)}"
}

# Input locals
############################
## subneting of VPC
locals {
    public_subnets = [
        {
            purpose = "pub-common"
            zone = "${var.REGION}a" ## Must be put a AZs alphabet
            cidr = "10.0.0.0/28"
        }, 
        {
            purpose = "pub-common"
            zone = "${var.REGION}c"
            cidr = "10.0.0.16/28"
        }
    ]
    squid_proxy_subnets = [
        {
            purpose = "pri-squid"
            zone = "${var.REGION}a"
            cidr = "10.0.0.32/28"
        },
        {
            purpose = "pri-squid"
            zone = "${var.REGION}c"
            cidr = "10.0.0.48/28"
        }
    ]
    private_subnets = [
        {
            purpose = "pri-sub"
            zone = "${var.REGION}a"
            cidr = "10.0.0.64/26"
        },
        {
            purpose = "pri-sub"
            zone = "${var.REGION}c"
            cidr = "10.0.0.128/25"
        }
    ]
    
    zone_index = {
        "a" = 0,
        "c" = 1
    }

    nat_gateway_count = var.enable_nat ? var.single_nat ? 1 : length(local.public_subnets) : 0
}

resource "random_id" "random" {
    byte_length = 4
}
