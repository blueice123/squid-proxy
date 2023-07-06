output "vpc_arn" {
    value = aws_vpc.main.arn
}

output "web_ec2_id" {
    value = aws_instance.web[*].id == null ? null : aws_instance.web[*].id
}
