locals{ ## workspace 별로 배포되는 AWS 계정을 여러개로 분리, 이는 provider 에서 정의 됨
    dev  = "${terraform.workspace == "dev" ? "239234376445": ""}"
    qa   = "${terraform.workspace == "qa" ? "239234376445": ""}"
    prod = "${terraform.workspace == "prod" ? "239234376445": ""}" 
    account_num    = "${coalesce(local.dev, local.qa, local.prod)}"
}