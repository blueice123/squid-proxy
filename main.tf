resource "aws_vpc" "main" {
    cidr_block = "10.0.0.0/16"

    tags = {
        Name = format("%s_vpc", terraform.workspace)
    }
}

resource "aws_instance" "web" { # 워크스페이스 별로 생성해야될 리소스와 그렇지 않아야할 리소스 구분 
    # precondition이 아니라 count로도 워크스페이스별 리소스 생성 혹은 하지 않음을 정의할 수 있음
    count = terraform.workspace == "prod" ? 1 : 0  
   
    ami           = "ami-0425f132103cb3ed8"
    instance_type = "t2.micro"

#   lifecycle {  ## 워크스페이스 별 리소스 생성 유무를 precondition으로 해버리면 다른 워크스페이스에서는 tf error가 발생한다. 
#     precondition {
#       condition     = terraform.workspace == "prod" ? true : false
#       error_message = "Terraform workspace: prod가 아닙니다."
#     }
#   }

    tags = {
        Name = format("%s_ec2", terraform.workspace)
    }
}