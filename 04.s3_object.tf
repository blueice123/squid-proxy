## /etc/squid/whitelist.txt 때문에 필요함 

resource "aws_s3_bucket" "squid" {
  bucket = format("%s-%s-squid", var.project_code, terraform.workspace)

#   tags = {
#     Name        = "My bucket"
#     Environment = "Dev"
#   }
}