variable "REGION" {
    default = "ap-northeast-2"
}

variable "ACCOUNT" {
    ## 내 로컬PC에 저장된 CTC AWS 계정의 IAM AccessKey profile 이름을 명시
    ## mine profile은 script/aws-token.sh 스크립트 실행을 통해 MFA에 인증한 임시 토큰 값
    default = "mine"
}


variable "project_code" {  
    default = "nh"
}

variable "key_pair" {
    default = "seoul-ekgu-key"
}


############################
## VPC base parameters
variable "vpc_cidr" {
    description = "The CIDR block for the VPC. Default value is a valid CIDR, but not acceptable by AWS and should be overridden"
    type        = string
    default     = "10.0.0.0/24"
}
variable "enable_nat" {
    description = "If you don't have to create nat, you are defined false"
    type    = bool
    default = true
}
variable "single_nat" {
    description = "All public subnet NAT G/W install or not"
    type    = bool
    default = true
}

############################
## VPC base parameters2 
variable "enable_dns_hostnames" {
    description = "Should be true to enable DNS hostnames in the VPC"
    type        = bool
    default     = true
}
variable "enable_dns_support" {
    description = "Should be true to enable DNS support in the VPC"
    type        = bool
    default     = true
}
variable "instance_tenancy" {
    description = "A tenancy option for instances launched into the VPC"
    type        = string
    default     = "default"
}
variable "assign_generated_ipv6_cidr_block" {
    description = "Define whether to use ipv6"
    type        = string
    default     = "false"
}
