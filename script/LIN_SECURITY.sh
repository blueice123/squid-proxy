#!/bin/bash

# File Backup
sudo cp -rp /etc/ssh/sshd_config /etc/ssh/sshd_config_$TM
sudo cp -rp /etc/pam.d/su /etc/pam.d/su_$TM
sudo cp -rp /etc/group /etc/group_$TM
sudo cp -rp /etc/audit/audit.rules /etc/audit/audit.rules_$TM
sudo cp -rp /etc/audit/rules.d/audit.rules /etc/audit/rules.d/audit.rules_$TM
sudo cp -rp /etc/selinux/config /etc/selinux/config_$TM

## Update 
sudo yum update -y 

## Settings the timezone
sudo timedatectl set-timezone Asia/Seoul

## User Add
sudo groupadd --gid 1001 sysadm 
sudo useradd --uid 1001 --gid 1001 sysadm 
echo "sysadm:Megazone123!" | chpasswd
# nsap sysadm UID 1001 GID 1001
# sap sysadm UID 1001 GID 100

## Change the SSH configure
# sudo sed -i 's/#   Port 22/Port 20022/g' /etc/ssh/ssh_config
# sudo sed -i 's/#Port 22/Port 20022/g' /etc/ssh/sshd_config 
sudo sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/ssh_config
sudo sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config 
sudo sed -i'' -r -e "/root    ALL=(ALL)       ALL/a\sysadm    ALL=(ALL)       ALL/" /etc/sudoers
sudo echo "sysadm ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/90-cloud-init-users
sudo systemctl restart sshd

# (CIS_Linux_2.0.0 - 5.2.1) Ensure permissions on /etc/ssh/sshd_config are configured
# File permissions not configured properly, expected: 600, actual: 640. Full path: /etc/ssh/sshd_config
sudo chmod 600 /etc/ssh/sshd_config

# (CIS_Linux_2.0.0 - 5.2.10) Ensure SSH root login is disabled
# The sshd configuration value PermitRootLogin is set to "yes" but expected to match "no". File /etc/ssh/sshd_config
sudo sed -i 's/PermitRootLogin yes/PermitRootLogin no/g' /etc/ssh/sshd_config 

# (CIS_Linux_2.0.0 - 5.6) Ensure access to the su command is restricted
# su command is not restricted, file /etc/pam.d/su
GET_SYSADM_UID=$(sudo id -u sysadm)
if [ -n "$GET_SYSADM_UID" ]; then
  sudo usermod -a -G wheel sysadm
  ## SRV-122 UMASK 설정 미흡 
  # (CIS_Amazon_Linux2_1.0.0 - 5.4.4) Ensure default user umask is 027 or more restrictive
  # https://secscan.acron.pl/centos7/5/4/4
  SYSADM_UMASK=$(sudo grep "umask 027" /home/sysadm/.bashrc)
  if [ -n "$SYSADM_UMASK" ]; then
    echo "UMASK sysadm 설정이 완료됨"
  else 
    sudo echo "umask 027" >> /home/sysadm/.bashrc
  fi
else
  echo "sysadm 계정이 없음 미완료 - su command is not restricted, file /etc/pam.d/su"
fi
sudo chmod 4750 /usr/bin/su
sudo chown root.wheel /usr/bin/su
PAMD_WHEEL_CHECK=$(sudo grep "pam_wheel.so debug group=wheel" /etc/pam.d/su)
if [ -n "$PAMD_WHEEL_CHECK" ]; then
  echo "pam.d/su 이미 설정되어 있음"
else 
  sudo echo "auth            required        pam_wheel.so debug group=wheel" >> /etc/pam.d/su
fi

# (CIS_Amazon_Linux2_1.0.0 - 1.6.1.2) Ensure the SELinux state is enforcing
# The SELinux configuration value SELINUX is set to "disabled" but expected to match "enforcing". File /etc/selinux/config
sudo sed -i 's/SELINUX=disabled/SELINUX=permissive/g' /etc/selinux/config

# (CIS_Linux_2.0.0 - 5.1.8) Ensure at/cron is restricted to authorized users
# Forbidden cron file exists. File /etc/cron.deny
# Forbidden cron file exists. File /etc/at.deny
CRON_DENY_CHECK=/etc/cron.deny
if [ -f "$CRON_DENY_CHECK" ]; then
  sudo mv /etc/cron.deny /etc/cron.deny_$TM
else
  echo "cron.deny 존재하지 않음 -(CIS_Linux_2.0.0 - 5.1.8) Ensure at/cron is restricted to authorized users"
fi
CRON_AT_CHECK=/etc/at.deny
if [ -f "$CRON_AT_CHECK" ]; then
  sudo mv /etc/at.deny /etc/at.deny_$TM
else
  echo "at.deny 존재하지 않음 -(CIS_Linux_2.0.0 - 5.1.8) Ensure at/cron is restricted to authorized users"
fi
sudo touch /etc/cron.d/cron.allow && sudo chmod 600 /etc/cron.d/cron.allow && sudo chown root:root /etc/cron.d/cron.allow 
CRON_ALLOW_ROOT_CHECK1=$(sudo grep "root" /etc/cron.d/cron.allow)
CRON_ALLOW_SYSADM_CHECK1=$(sudo grep "sysadm" /etc/cron.d/cron.allow)
if [ -n "$CRON_ALLOW_ROOT_CHECK1" ]; then
  echo "cron.d/cron.allow root 설정되어 있음 - (CIS_Linux_2.0.0 - 5.6) Ensure access to the su command is restricted"
else 
  sudo echo "root" >> /etc/cron.d/cron.allow
fi
if [ -n "$CRON_ALLOW_SYSADM_CHECK1" ]; then
  echo "cron.d/cron.allow sysadm 설정되어 있음 - (CIS_Linux_2.0.0 - 5.6) Ensure access to the su command is restricted"
else 
  sudo echo "sysadm" >> /etc/cron.d/cron.allow
fi 
sudo touch /etc/cron.allow 
sudo touch /etc/at.allow 
sudo chmod og-rwx /etc/cron.allow 
sudo chmod og-rwx /etc/at.allow 
sudo chown root:root /etc/cron.allow 
sudo chown root:root /etc/at.allow
CRON_ALLOW_ROOT_CHECK2=$(sudo grep "root" /etc/cron.allow)
CRON_ALLOW_SYSADM_CHECK2=$(sudo grep "sysadm" /etc/cron.allow)
if [ -n "$CRON_ALLOW_ROOT_CHECK2" ]; then
  echo "crontab root 설정되어 있음 - (CIS_Linux_2.0.0 - 5.6) Ensure access to the su command is restricted"
else 
  sudo echo "root" >> /etc/cron.allow
  sudo echo "root" >> /etc/at.allow
fi
if [ -n "$CRON_ALLOW_SYSADM_CHECK2" ]; then
  echo "crontab sysadm 설정되어 있음 - (CIS_Linux_2.0.0 - 5.6) Ensure access to the su command is restricted"
else 
  sudo echo "sysadm" >> /etc/cron.allow
  sudo echo "sysadm" >> /etc/at.allow
fi



# (CIS_Linux_2.0.0 - 5.1.3) Ensure permissions on /etc/cron.hourly are configured
# (CIS_Linux_2.0.0 - 5.1.4) Ensure permissions on /etc/cron.daily are configured
# (CIS_Linux_2.0.0 - 5.1.5) Ensure permissions on /etc/cron.weekly are configured
# (CIS_Linux_2.0.0 - 5.1.6) Ensure permissions on /etc/cron.monthly are configured
# (CIS_Linux_2.0.0 - 5.1.7) Ensure permissions on /etc/cron.d are configured
# File permissions not configured properly, expected: 700, actual: 755. Full path: /etc/cron.hourly
# File permissions not configured properly, expected: 700, actual: 755. Full path: /etc/cron.daily
# File permissions not configured properly, expected: 700, actual: 755. Full path: /etc/cron.weekly
# File permissions not configured properly, expected: 700, actual: 755. Full path: /etc/cron.monthly
# File permissions not configured properly, expected: 700, actual: 755. Full path: /etc/cron.d
sudo chmod -R 700  /etc/cron.hourly
sudo chmod -R 700  /etc/cron.daily
sudo chmod -R 700  /etc/cron.weekly
sudo chmod -R 700  /etc/cron.monthly
sudo chmod 700  /etc/cron.d

# (CIS_Amazon_Linux2_1.0.0 - 5.1.2) Ensure permissions on /etc/crontab are configured
# File permissions not configured properly, expected: 600, actual: 644. Full path: /etc/crontab
sudo chmod 600 /etc/crontab

CIS_CHECK=/etc/audit/rules.d/cis_linux.rules
if [ -f "$CIS_CHECK" ]; then
  echo "CIS Linux rules 파일이 존재함"
else 
  # (CIS_Linux_2.0.0 - 4.1.16) Ensure changes to system administration scope (sudoers) is collected
  # Missing auditd rule for files: /etc/sudoers, /etc/sudoers.d/.
  # https://secscan.acron.pl/centos7/4/1/15
  sudo echo "-w /etc/sudoers -p wa -k scope"   >> /etc/audit/rules.d/cis_linux.rules
  sudo echo "-w /etc/sudoers.d -p wa -k scope" >> /etc/audit/rules.d/cis_linux.rules

  # (CIS_Linux_2.0.0 - 4.1.18) Ensure kernel module loading and unloading is collected
  # Missing auditd rule for files: /sbin/insmod, /sbin/rmmod, /sbin/modprobe.
  # (CIS_Linux_2.0.0 - 4.1.18) Ensure kernel module loading and unloading is collected
  # Missing auditd rule for syscalls: init_module, delete_module.
  # https://www.tenable.com/audits/items/CIS_Amazon_Linux_2_STIG_v1.0.0_L2.audit:6daea36845dee304c33bdceae81fa02c
  sudo echo "-w /sbin/insmod -p x -k modules"                                          >> /etc/audit/rules.d/cis_linux.rules
  sudo echo "-w /sbin/rmmod -p x -k modules"                                           >> /etc/audit/rules.d/cis_linux.rules
  sudo echo "-w /sbin/modprobe -p x -k modules"                                        >> /etc/audit/rules.d/cis_linux.rules
  sudo echo "-a always,exit -F arch=b64 -S init_module -S delete_module -k modules"    >> /etc/audit/rules.d/cis_linux.rules

  # (CIS_Linux_2.0.0 - 4.1.14) Ensure successful file system mounts are collected
  # Missing auditd rule for syscall: mount.
  # https://secscan.acron.pl/centos7/4/1/13
  sudo echo "-a always,exit -F arch=b32 -S mount -F auid>=1000 -F auid!=4294967295 -k mounts"  >> /etc/audit/rules.d/cis_linux.rules
  sudo echo "-a always,exit -F arch=b64 -S mount -F auid>=1000 -F auid!=4294967295 -k mounts" >> /etc/audit/rules.d/cis_linux.rules

  # (CIS_Linux_2.0.0 - 4.1.19) Ensure the audit configuration is immutable
  # Audit rules can be modified with auditctl
  # https://secscan.acron.pl/centos7/4/1/18
  sudo echo "-e 2" >> /etc/audit/rules.d/cis_linux.rules
fi

# (CIS_Linux_2.0.0 - 6.2.8) Ensure users' home directories permissions are 750 or more restrictive
# Home directory permissions of 2 users are more permissive than 750, e.g /home/ec2-user:755
sudo chmod o-rwx -R /home/ec2-user/ 2> /dev/null
sudo chmod o-rwx -R /home/sysadm/ 2> /dev/null

## Change the SSH configure
# sudo sed -i 's/#   Port 22/Port 20022/g' /etc/ssh/ssh_config
# sudo sed -i 's/#Port 22/Port 20022/g' /etc/ssh/sshd_config 
sudo sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/ssh_config
sudo sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config 
SYSADM_ROOT_PROMOTE_CHECK=$(sudo grep "sysadm ALL=(ALL) NOPASSWD:ALL" /etc/sudoers.d/90-cloud-init-users)
if [ -n "$SYSADM_ROOT_PROMOTE_CHECK" ]; then
  echo "sysadm root 승격 권한이 이미 존재함"
else 
  sudo echo "sysadm ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/90-cloud-init-users
fi
systemctl restart sshd

## 보안 조치 스크립트
## SRV-028 원격 터미널 접속 타임아웃 설정 미흡
TIMEOUT=$(sudo grep "TIMEOUT=600" /etc/profile)
if [ -n "$TIMEOUT" ]; then
  echo "Session TIMEOUT 설정이 완료됨"
else 
  sudo echo "TIMEOUT=600" >> /etc/profile
  sudo echo "TIMEOUT 600" >> /etc/csh.login 
fi
sudo sed -i 's/#ClientAliveInterval 0/ClientAliveInterval 300/g' /etc/ssh/sshd_config 
sudo sed -i 's/#ClientAliveCountMax 3/ClientAliveCountMax 1/g' /etc/ssh/sshd_config 


## SRV-122 UMASK 설정 미흡 
# (CIS_Amazon_Linux2_1.0.0 - 5.4.4) Ensure default user umask is 027 or more restrictive
# https://secscan.acron.pl/centos7/5/4/4
sudo sed -i 's/#umask 022/umask 027/g' /etc/profile 
sudo sed -i 's/umask 022/umask 027/g' /etc/profile
sudo sed -i 's/umask 022/umask 027/g' /etc/bashrc
EC2_USER_UMASK=$(sudo grep "umask 027" /home/ec2-user/.bashrc)
if [ -n "$EC2_USER_UMASK" ]; then
  echo "UMASK ec2-user 설정이 완료됨"
else 
  sudo echo "umask 027" >> /home/ec2-user/.bashrc
fi
ROOT_UMASK=$(sudo grep "umask 027" /root/.bashrc)
if [ -n "$ROOT_UMASK" ]; then
  echo "UMASK root 설정이 완료됨"
else 
  sudo echo "umask 027" >> /root/.bashrc
fi

## SRV-133 Cron 서비스 사용 계정 제한 미비
# sudo echo "
# lp
# games
# nobody
# ec2-user
# " >> /etc/cron.deny 
# sudo touch /etc/cron.allow && echo "root" >> /etc/cron.allow
## 아래 2개의 항목으로 대체 함 
# (CIS_Linux_2.0.0 - 5.1.8) Ensure at/cron is restricted to authorized users
# Forbidden cron file exists. File /etc/cron.deny
# (CIS_Linux_2.0.0 - 5.1.8) Ensure at/cron is restricted to authorized users
# Forbidden cron file exists. File /etc/at.deny


## SRV-081 Crontab 설정관리 권한 설정 미흡
# sudo chmod 0640 /etc/cron.allow

## SRV-163 시스템 사용 주의사항 미출력
sudo update-motd --disable
sudo echo -e '############################################################### 
######################  === WARNING ===  ######################
###############################################################
###############################################################
#                                                             #
#  This System is for the use of authorized users only.       #
#  Individuals using this computer system without authority,  #
#  or in  excess of their authority, are subject to having    #
#  all of their activities on this system monitored and       #
#  recorded by system personnel.                              #
#                                                             #
#  In the course of monitoring individuals improperly using   #
#  this system, or in the course of system maintenance,       #
#  the activities of authorized users may also be monitored.  #
#                                                             #
#  Anyone using this system expressly consents to such        #
#  monitoring and is advised that if such monitoring reveals  #
#  possible evidence of criminal activity, system personnel   #
#  may provide the evidence of such monitoring to law         #
#  enforcement officials.                                     #
#                                                             #
#                                                             #
###############################################################' > /etc/motd

sudo echo -e '############################################################### 
######################  === WARNING ===  ######################
###############################################################
###############################################################
#                                                             #
#  This System is for the use of authorized users only.       #
#  Individuals using this computer system without authority,  #
#  or in  excess of their authority, are subject to having    #
#  all of their activities on this system monitored and       #
#  recorded by system personnel.                              #
#                                                             #
#  In the course of monitoring individuals improperly using   #
#  this system, or in the course of system maintenance,       #
#  the activities of authorized users may also be monitored.  #
#                                                             #
#  Anyone using this system expressly consents to such        #
#  monitoring and is advised that if such monitoring reveals  #
#  possible evidence of criminal activity, system personnel   #
#  may provide the evidence of such monitoring to law         #
#  enforcement officials.                                     #
#                                                             #
#                                                             #
###############################################################' > /etc/issue.net

## 기타 사항 rsys 로그파일
sudo chmod 0640 /etc/rsyslog.conf 

## SRV-087 C캄파일러 존재 및 권한 설정 미흡 
sudo chmod 750 /usr/bin/gcc 

## SRV-108 로그에 대한 접근 통제 및 관리 미흡
sudo chmod 644 /var/log/fabricmanager.log 

## SRV-144 /dev/ 경로에 불필요한 파일 존재
# /dev/termination-log 경로는 K8S 환경에서 POD의 종료 메시지를 지정하는 기본 경로로 삭제하면 안됨

## SRV-091 불필요하게 SUID, SGID bit가 설정
sudo chmod -s /usr/bin/newgrp
sudo chmod -s /usr/sbin/unix_chkpwd

## SRV-096 사용자 환경파일의 소유자 또는 권한 설정 미흡 
sudo chmod 0640 /root/.cshrc
sudo chmod 0640 /root/.bashrc
sudo chmod 0640 /root/.bash_profile
sudo chmod 0640 /home/ec2-user/.bashrc
sudo chmod 0640 /home/ec2-user/.bash_profile
sudo chmod 0640 /home/docker/.bash_profile
sudo chmod 0640 /home/docker/.bashrc