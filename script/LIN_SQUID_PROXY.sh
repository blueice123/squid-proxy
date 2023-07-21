#!/bin/bash

# Terraform data에서 변수 받아서 S3 name 추출 
S3Bucket=`echo $1`
PRIVATE_SUB_RT_ID=`echo $2`

####### Application setup start ####
sudo echo 1 > /proc/sys/net/ipv4/ip_forward

sudo mkdir -p /home/ec2-user/package/squid/
sudo mkdir -p /home/ec2-user/package/iptables/
sudo mkdir -p /home/ec2-user/package/cronie/
sudo yum install squid -y --downloadonly --downloaddir=/home/ec2-user/package/squid/ && sudo rpm -Uvh /home/ec2-user/package/squid/*
sudo yum install iptables -y --downloadonly --downloaddir=/home/ec2-user/package/iptables/ && sudo rpm -Uvh /home/ec2-user/package/iptables/*
sudo yum install cronie -y --downloadonly --downloaddir=/home/ec2-user/package/cronie/ && sudo rpm -Uvh /home/ec2-user/package/cronie/* && sudo systemctl enable crond && sudo systemctl start crond

### squid setup 
sudo echo '.amazonaws.com
.api.aws
.cloudfront.net
.aws.amazon.com
.awsstatic.com
.awsapps.com
ap-northeast-2.console.aws.amazon.com
ap-northeast-2.signin.aws.amazon.com
.aws.dev
.aws.a2z.com' > /etc/squid/whitelist.txt 

sudo echo 'visible_hostname squid
cache deny all 

# Log format and rotation 
logformat splunk_recommended_squid %ts.%03tu logformat=splunk_recommended_squid duration=%tr src_ip=%>a src_port=%>p dest_ip=%<a dest_port=%<p user_ident="%[ui" user="%[un" local_time=[%tl] http_method=%rm request_method_from_client=%<rm request_method_to_server=%>rm url="%ru" http_referrer="%{Referer}>h" http_user_agent="%{User-Agent}>h" status=%>Hs vendor_action=%Ss dest_status=%Sh total_time_milliseconds=%<tt http_content_type="%mt" bytes=%st bytes_in=%>st bytes_out=%<st sni="%ssl::>sni"
access_log daemon:/var/log/squid/splunk_access.log splunk_recommended_squid
logfile_rotate 10
debug_options rotate=10

# Handle HTTP requests 
http_port 3128
http_port 3129 intercept

# Handle HTTPS requests 
https_port 3130 cert=/etc/squid/ssl/squid.pem ssl-bump intercept
acl SSL_port port 443
http_access allow SSL_port
acl step1 at_step SslBump1
acl step2 at_step SslBump2
acl step3 at_step SslBump3
ssl_bump peek step1 all

# Deny requests to proxy instance metadata 
acl instance_metadata dst 169.254.169.254
http_access deny instance_metadata

# Filter HTTP requests based on the whitelist 
acl allowed_http_sites dstdomain "/etc/squid/whitelist.txt"
http_access allow allowed_http_sites

# Filter HTTPS requests based on the whitelist 
acl allowed_https_sites ssl::server_name "/etc/squid/whitelist.txt"
ssl_bump peek step2 allowed_https_sites
ssl_bump splice step3 allowed_https_sites
ssl_bump terminate step2 all
http_access allow allowed_https_sites

http_access deny all' > /etc/squid/squid.conf

### iptables setup
sudo echo "sudo iptables -t nat -A PREROUTING -p tcp --dport 80 -j REDIRECT --to-port 3129
sudo iptables -t nat -A PREROUTING -p tcp --dport 443 -j REDIRECT --to-port 3130" > /etc/squid/iptables.sh && sudo chmod 755 /etc/squid/iptables.sh && sudo echo "@reboot root /etc/squid/iptables.sh">> /etc/crontab && sudo bash /etc/squid/iptables.sh


### Create a SSL certificate for the SslBump Squid module
sudo mkdir /etc/squid/ssl
sudo cd /etc/squid/ssl
sudo openssl genrsa -out /etc/squid/ssl/squid.key 4096
sudo openssl req -new -key /etc/squid/ssl/squid.key -out /etc/squid/ssl/squid.csr -subj "/C=XX/ST=XX/L=squid/O=squid/CN=squid"
sudo openssl x509 -req -days 3650 -in /etc/squid/ssl/squid.csr -signkey /etc/squid/ssl/squid.key -out /etc/squid/ssl/squid.crt
sudo cat /etc/squid/ssl/squid.key /etc/squid/ssl/squid.crt >> /etc/squid/ssl/squid.pem
sudo /usr/lib64/squid/security_file_certgen -c -s /var/spool/squid/ssl_db -M 20MB

### squid start 
sudo chown -R squid. /etc/squid/* 
sudo chown -R squid.  /var/spool/squid/ssl_db/
sudo squid -k parse && squid -k reconfigure
systemctl enable squid && systemctl start squid

# Schedule tasks
echo "sudo mkdir -p /etc/squid/old/
sudo cp -rp /etc/squid/* /etc/squid/old/
sudo aws s3 cp s3://$S3Bucket/whitelist.txt /etc/squid/whitelist.txt 
sudo chown -R squid. /etc/squid/
sudo /usr/sbin/squid -k parse && sudo /usr/sbin/squid -k reconfigure || (sudo cp -rp /etc/squid/old/whitelist.txt /etc/squid/whitelist.txt; exit 1)
" > /etc/squid/squid-conf-refresh.sh && sudo chmod 755 /etc/squid/squid-conf-refresh.sh

echo "* * * * * root /etc/squid/squid-conf-refresh.sh
0 0 * * * root /usr/sbin/squid -k rotate" >> /etc/crontab

TOKEN=`curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600"`
MAC_ADDR=`curl -H "X-aws-ec2-metadata-token: $TOKEN" -v http://169.254.169.254/latest/meta-data/network/interfaces/macs`
SUBNET_ID=`curl -H "X-aws-ec2-metadata-token: $TOKEN" -v http://169.254.169.254/latest/meta-data/network/interfaces/macs/$MAC_ADDR/subnet-id`
IPv4_ADDR=`curl -H "X-aws-ec2-metadata-token: $TOKEN" -v http://169.254.169.254/latest/meta-data/local-ipv4`
ENI_ID=`aws ec2 describe-network-interfaces --filters Name=addresses.private-ip-address,Values=$IPv4_ADDR --query NetworkInterfaces[].NetworkInterfaceId --output text`
ROUTE_ID=`aws ec2 describe-route-tables --filters Name=association.subnet-id,Values=$SUBNET_ID --query RouteTables[].RouteTableId --output text`

## route table 경로 변경
aws ec2 create-route --route-table-id $PRIVATE_SUB_RT_ID --destination-cidr-block 0.0.0.0/0 --network-interface-id $ENI_ID
aws ec2 replace-route --route-table-id $PRIVATE_SUB_RT_ID --destination-cidr-block 0.0.0.0/0 --network-interface-id $ENI_ID