provider "aws" {
    region  = var.REGION
    profile = var.ACCOUNT # = mine profile = CTC 메인계정

    assume_role {
        # = 고객사 Account의 assume role ARN 
        role_arn = "arn:aws:iam::${local.account_num}:role/mzc_solutions_architect" 
    }

    default_tags {
        tags = {
            terraform = "enable"
            Environment = format("%s", terraform.workspace)
        }
    }
}



