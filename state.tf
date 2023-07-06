terraform {
    backend "s3" {
    region         = "ap-northeast-2"
    bucket         = "megazone-terraform"
    dynamodb_table = "megazone-terraform"
    key            = "workspace_test.tfstate"
    encrypt        = true
  }
  required_version = ">= 0.12"
}


data "terraform_remote_state" "prod_workspace" {  ## prod workspace의 remote tf 
    backend = "s3"
    config = {
        region = "ap-northeast-2"
        bucket = "megazone-terraform"
        key    = "env:/prod/workspace_test.tfstate"
    }
}
data "terraform_remote_state" "qa_workspace" { ## qa workspace의 remote tf 
    backend = "s3"
    config = {
        region = "ap-northeast-2"
        bucket = "megazone-terraform"
        key    = "env:/qa/workspace_test.tfstate"
    }
}