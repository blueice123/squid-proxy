terraform {
    backend "s3" {
    region         = "ap-northeast-2"
    bucket         = "megazone-terraform"
    dynamodb_table = "megazone-terraform"
    key            = "squid_proxy.tfstate"
    encrypt        = true
  }
  required_version = ">= 0.12"
}
