#!/bin/bash -x

## Note 
# 1. NH의 Splunk로 추출할 수 있기에 로그를 외부로 빼내는건 일부러 설정하지 않음
# 2. yum으로 설치되는 패키지들(squid, crond, iptables)과 script는 특정 S3 bucket에 올려서 설치하게끔 스크립트 변경할 것 
## 관련 자료#01: https://aws.amazon.com/ko/blogs/security/how-to-add-dns-filtering-to-your-nat-instance-with-squid/
## 관련자료 #02: https://aws.amazon.com/ko/blogs/security/how-to-set-up-an-outbound-vpc-proxy-with-domain-whitelisting-and-content-filtering/
# 3. Security 부분에 ec2-user를 대체하는 일반계정(sysadm)을 만듬.. id/pw 커스텀 해야함 

# Redirect the user-data output to the console logs
exec >> >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

# Environment setup
PRIVATE_SUB_RT=`echo "${PRIVATE_SUB_RT_ID}"`
SQUID_BUCKET=`echo "${S3_Bucket_ARN}" | awk -F":" '{print $6}'`
sudo echo $PRIVATE_SUB_RT $SQUID_BUCKET > /tmp/variables.txt

# download script 
sudo yum install -y git
sudo git clone https://github.com/blueice123/script.git

# excute
bash -x ./script/LIN_SECURITY.sh 2> /var/log/user-data_LIN_SECURITY.log 2>&1
bash -x ./script/LIN_SQUID_PROXY.sh $SQUID_BUCKET $PRIVATE_SUB_RT 2> /var/log/user-data_LIN_SQUID_PROXY.log 2>&1