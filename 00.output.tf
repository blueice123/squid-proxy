# output "vpc_arn" {
#     value = aws_vpc.main.arn
# }

# output "web_ec2_id" {
#     value = aws_instance.web[*].id == null ? null : aws_instance.web[*].id
# }

output "my_terraform_environmnet_public_ip" {
  value = "${chomp(data.http.icanhazip.body)}/32"
}