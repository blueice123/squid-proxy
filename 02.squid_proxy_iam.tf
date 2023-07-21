resource "aws_iam_instance_profile" "squid" {
    name  = "squid"
    role = aws_iam_role.squid.id
}

resource "aws_iam_role" "squid" {
    name = format("%s-%s-squid", var.project_code, terraform.workspace)

    assume_role_policy = <<EOF
        {
            "Version": "2012-10-17",
            "Statement": [
                {
                "Sid": "",
                "Effect": "Allow",
                "Principal": {
                    "Service": "ec2.amazonaws.com"
                },
                "Action": "sts:AssumeRole"
                }
            ]
        }
        EOF
}

resource "aws_iam_role_policy" "squid" {
    name = format("%s-%s-squid", var.project_code, terraform.workspace)
    role = aws_iam_role.squid.id

    policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "ec2:ReplaceRoute",
                "ec2:CreateRoute"
                ],
            "Resource": [
                "arn:aws:ec2:${var.REGION}:${data.aws_caller_identity.current.account_id}:route-table/${aws_route_table.private_subnets.id}"
            ]
        },
        {
            "Sid": "VisualEditor1",
            "Effect": "Allow",
            "Action": [
                "s3:ListBucket",
                "s3:GetObject",
                "s3:ListBucket",
                "s3:PutObject",
                "s3:PutObjectAcl",
                "s3:PutObjectTagging",
                "s3:GetObjectTagging",
                "s3:GetObjectVersion",
                "s3:GetObjectVersionTagging"
            ],
            "Resource": [
                "${aws_s3_bucket.squid.arn}",
                "${aws_s3_bucket.squid.arn}/*"
            ]
        },
        {
            "Sid": "VisualEditor2",
            "Effect": "Allow",
            "Action": [
                "ec2:DescribeRouteTables",
                "ec2:DescribeAddresses",
                "ec2:DescribeNetworkInterfaces"
            ],
            "Resource": "*"
        }
    ]
}
    EOF
}

