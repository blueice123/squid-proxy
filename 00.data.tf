data "aws_ami" "amz2023" {
    most_recent = true
    filter {
        name   = "name"
        values = ["al2023-ami-2023.1.20230705.0-kernel-6.1-x86_64"]
    }
    filter {
        name   = "virtualization-type"
        values = ["hvm"]
    }
    owners = ["137112412989"] 
}

data "template_file" "squid" {
    template = file("./script/squid_setting.sh")
    vars = {
        S3_Bucket_ARN = "${aws_s3_bucket.squid.arn}"
        PRIVATE_SUB_RT_ID = "${aws_route_table.private_subnets.id}"
    }
}


# aws account id 
data "aws_caller_identity" "current" {}

data "http" "icanhazip" {
    url = "http://icanhazip.com"
}

