
resource "aws_instance" "squid_proxy" {
  ami = data.aws_ami.amz2023.id #"ami-0221383823221c3ce" #Amazon Linux 2023 AMI
  associate_public_ip_address = false
  instance_type               = "t2.micro"
  source_dest_check           = false #default true
  key_name                    = var.key_pair
  vpc_security_group_ids      = [aws_security_group.admin.id, aws_security_group.squid.id]
  subnet_id                   = aws_subnet.squid_proxy_subnets[0].id
  user_data                   = data.template_file.squid.rendered
  iam_instance_profile        = aws_iam_instance_profile.squid.name
  root_block_device {
    volume_type               = "gp3"
    volume_size               = "8" #var.root_volume_size
    delete_on_termination     = true
  }
  tags = {
    Name = format("%s-%s-squid", var.project_code, terraform.workspace)
    AWS_BACKUP = "enable"
  }
  # volume_tags = {
  #   Name = format(
  #     "%s-%s-CONNECTOR",
  #     var.company,
  #     var.environment
  #   )
  # }
}


