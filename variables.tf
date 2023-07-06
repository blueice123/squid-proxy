variable "REGION" {
    default = "ap-northeast-2"
}

variable "ACCOUNT" {
    ## 내 로컬PC에 저장된 CTC AWS 계정의 IAM AccessKey profile 이름을 명시
    ## mine profile은 script/aws-token.sh 스크립트 실행을 통해 MFA에 인증한 임시 토큰 값
    default = "mine"
}