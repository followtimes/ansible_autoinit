#!/bin/bash


#pwd 
pwd_dir=$(pwd)

#host passwd list file
pass_file=$pwd_dir/host_pass

#scp id_rsa.pub to remote linux
scp_rsapub_file=$pwd_dir/expect/expect_ssh.exp

#change sshd_config file 
change_sshd_config=$pwd_dir/expect/expect_change_sshd_config.exp

#change remote linux passwd to a 16 rand seq
change_passwd_file=$pwd_dir/expect/expect_change_passwd.exp


#playbook for test
play_book=$pwd_dir/../site-autoinit.yaml

#playbook for test
check_book=$pwd_dir/../site-check.yaml

#hosts file
hosts_file=$pwd_dir/../hosts

#auto_mount  file
auto_mount_file=$pwd_dir/automount_data_block_for_xiaomi.sh

#centos65_file
centos65_file=$pwd_dir/centos-65.sh

#kernel file 
kernel_file=$pwd_dir/kernel-ml-aufs-3.10.5-12.1.x86_64.rpm

#put file in /tmp
cp -fp $auto_mount_file            /tmp
cp -fp $centos65_file              /tmp
cp -fp $kernel_file                /tmp          

#creat the Ksyun.repo file
cat <<EOF>>/tmp/Ksyun.repo
[ksyun]
name=kingsoft cloud
baseurl=http://yum.ksyun.cn/ksyun/$releasever/$basearch/
gpgcheck=0
EOF



#loop initialization authentication
for host in `awk '{print $1}' $pass_file`
do
oldpasswd=`awk -v I="$host" '{if(I==$1) print $2}' $pass_file`

expect $scp_rsapub_file  $host $oldpasswd
ssh-add

expect $change_sshd_config $host $oldpasswd

new_passwd=$(cat /proc/sys/kernel/random/uuid | awk -F "-" '{print $1$2$3}')
expect $change_passwd_file  $host $new_passwd

done

#ansible_playbooks 
ansible-playbook  -i $hosts_file  $play_book   -vvv 
#ansible_playbooks 
ansible-playbook  -i $hosts_file  $check_book  -vvv 

#remove the file
rm -f /tmp/automount_data_block_for_xiaomi.sh
rm -f /tmp/centos-65.sh
rm -f /tmp/kernel-ml-aufs-3.10.5-12.1.src.rpm






