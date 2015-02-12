#!/bin/bash

source /etc/profile

export black='\e[0m\c'
export boldblack='\e[1;0m\c'
export red='\e[31m\c'
export boldred='\e[1;31m\c'
export green='\e[32m\c'
export boldgreen='\e[1;32m\c'
export yellow='\e[33m\c'
export boldyellow='\e[1;33m\c'
export blue='\e[34m\c'
export boldblue='\e[1;34m\c'
export magenta='\e[35m\c'
export boldmagenta='\e[1;35m\c'
export cyan='\e[36m\c'
export boldcyan='\e[1;36m\c'
export white='\e[37m\c'
export boldwhite='\e[1;37m\c'

cecho ()
{
        local default_msg="No message passed."
                message=${1:-$default_msg}      # Defaults to default message.
                color=${2:-$black}              # Defaults to black, if not specified.

                if [ "$3" == "NOLF" ];then
                {
                        echo -ne "$color"
                                echo -ne "$message"
                                tput sgr0                     # Reset to normal.
                                echo -ne "$black"
                }
                else
                {
                        echo -e "$color"
                                echo -e "$message"
                                tput sgr0                     # Reset to normal.
                                echo -e "$black"
                }
        fi

                return

}

#need root install
is_root=`id -u`
if [ $is_root -ne 0 ]
then
                echo "ERROR: MUST RUN BY ROOT!"
                exit 1
fi

#os version
is_centos=`cat /etc/issue | grep -ic '^CentOS release'`
SysVer=`cat /etc/issue |awk '{print $3}'|head -n 1`
macrover=`echo $SysVer | awk -F'.' '{ print $1}'`
if  [ $is_centos -eq 0 ]
then
                echo "ERROR: MUST RUN IN CENTOS 5/6!"
                exit 1
fi
if  [ $macrover -ne 5 -a  $macrover -ne 6  ]
then
                echo "ERROR: MUST RUN IN CENTOS 5/6!"
                exit 1
fi

#user add
#useradd work -u 10000 -m -d /home/work
su - work -c "mkdir -p data"

#make dir
mkdir -p /home/work/soft/src && cd /home/work/soft/src
mkdir -p /home/work/opshell
chmod -R 755 /home/work
chown -R work.work /home/work

#check dns
dig www.xiaomi.com >/dev/null 2>&1
if [ $? -ne 0 ]
then
        echo "WARNNING: DNS resolv failed."
fi

rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-6
yum clean all;yum makecache

#config static routes

#config ntp

#time zone
rm -f /etc/localtime
cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

#config sysctl
rm -f /tmp/sysctl.conf
for a in fs.file-max fs.nr_open net.core.wmem_max kernel.sysrq net.ipv4.tcp_keepalive_time net.ipv4.tcp_fin_timeout net.ipv4.tcp_window_scaling net.ipv4.tcp_syncookies net.ipv4.conf.all.send_redirects net.ipv4.conf.all.accept_redirects net.ipv4.conf.all.accept_source_route net.ipv4.icmp_echo_ignore_broadcasts net.ipv4.icmp_ratelimit net.ipv4.conf.all.rp_filter net.ipv4.conf.default.rp_filter net.ipv4.conf.all.forwarding net.ipv4.tcp_synack_retries net.ipv4.tcp_tw_recycle net.ipv4.tcp_tw_reuse net.ipv4.ip_forward net.ipv4.ip_nonlocal_bind net.ipv4.conf.all.log_martians net.ipv4.conf.all.arp_ignore net.ipv4.conf.all.arp_announce net.ipv4.tcp_mem net.ipv4.tcp_max_orphans net.ipv4.tcp_max_syn_backlog net.ipv4.ip_local_port_range net.ipv4.tcp_max_tw_buckets net.ipv4.conf.lo.rp_filter net.ipv4.tcp_syn_retries net.ipv6.conf.all.disable_ipv6 net.ipv6.conf.default.disable_ipv6 net.ipv6.conf.lo.disable_ipv6;do grep -v $a /etc/sysctl.conf > /tmp/sysctl.conf;mv /tmp/sysctl.conf /etc/sysctl.conf;done
cat <<EOF>>/etc/sysctl.conf
fs.file-max = 12553500
fs.nr_open = 12453500
net.core.wmem_max = 1048576
kernel.sysrq = 0
net.ipv4.tcp_keepalive_time = 300
net.ipv4.tcp_fin_timeout = 15
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_syncookies = 1
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.icmp_ratelimit = 5
net.ipv4.conf.all.rp_filter = 2
net.ipv4.conf.default.rp_filter = 2
net.ipv4.conf.all.forwarding = 0
net.ipv4.tcp_synack_retries = 1
net.ipv4.tcp_tw_recycle = 1
net.ipv4.tcp_tw_reuse = 1
net.ipv4.ip_forward = 1
net.ipv4.ip_nonlocal_bind = 1
net.ipv4.conf.all.log_martians = 0
net.ipv4.conf.all.arp_ignore = 2
net.ipv4.conf.all.arp_announce = 2
net.ipv4.tcp_mem = 94500000 915000000 927000000
net.ipv4.tcp_max_orphans = 3276800
net.ipv4.tcp_max_syn_backlog = 65536
net.ipv4.ip_local_port_range = 15000 65000
net.ipv4.tcp_max_tw_buckets = 10000
net.ipv4.conf.lo.rp_filter = 0
net.ipv4.tcp_syn_retries = 1
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv6.conf.lo.disable_ipv6 = 1
net.ipv4.tcp_timestamps = 0
net.ipv4.tcp_tw_recycle = 0
net.ipv4.tcp_tw_reuse = 0
net.ipv4.tcp_congestion_control =  west
net.ipv4.tcp_slow_start_after_idle = 0
EOF
sysctl -p

#config syslog ---- need update 
#site=`hostname|awk -F- '{print $1}'`
#case "$site" in
#  a ) syslogip="10.20.100.246";;
#  b ) syslogip="10.100.2.246";;
#  c ) syslogip="192.168.0.246";;
#  *) syslogip="10.21.109.2";;
#esac

if [ -n "`cat /etc/issue | grep 'release 6'`" ]
  then
  rpm -q rsyslog >/dev/null || yum -y install rsyslog
  chkconfig rsyslog on
  sed -i '/@/d' /etc/rsyslog.conf
  echo "*.*                @$syslogip" >> /etc/rsyslog.conf
  /etc/init.d/rsyslog restart
fi

#config kernel ulimit
if [ $macrover -eq 6 ]
then
cat <<EOF>> /etc/security/limits.conf
*       hard    nofile  300240
*       soft    nofile  150240
*	soft	core	unlimited
EOF
cat <<EOF>> /etc/security/limits.conf
*       hard    nproc  3000240
*       soft    nproc  1500240
EOF
rm -f /etc/security/limits.d/90-nproc.conf
else
cat <<EOF>> /etc/security/limits.conf
*       hard    nofile  3000240
*       soft    nofile  1500240
EOF
fi

#install packages
yum -y remove yum-update yum-rhn-plugin yum-security
yum -y install 
yum -y install mcelog lrzsz sysstat iotop dstat socat htop curl iftop wget zip nmap tree lynx iptraf vim arptables_jf telnet
yum -y install gcc gcc-c++ autoconf libjpeg libjpeg-devel libpng libpng-devel freetype freetype-devel libxml2 libxml2-devel zlib zlib-devel glibc glibc-devel glib2 glib2-devel bzip2 bzip2-devel ncurses ncurses-devel curl curl-devel e2fsprogs e2fsprogs-devel krb5 krb5-devel libidn libidn-devel openssl openssl-devel  openldap-devel nss_ldap  pcre-devel libevent-devel libevent unzip ImageMagick  net-snmp  net-snmp-libs net-snmp-utils postfix ccze
yum -y install postfix mdadm arptables_jf unifdef redhat-rpm-config rng-utils redhat-lsb rpm-build screen
yum -y install freeipmi-bmc-watchdog
yum -y install git
yum -y update bash

#install ipmi

count=0
while [ $count -le 5 ]
do
    if chkconfig --list ipmi|grep -q '3:on'
    then
        break
    else
        chkconfig ipmi on
    fi
    count=`expr $count + 1`
done

yum -y install python-pip
pip-python install thrift
pip install zc-zookeeper-static
pip install zc.zk
pip install virtualenv

#others install----need update
#wget http://download.xxx/download/nload-0.7.2.tar.gz
#tar zxvf nload-0.7.2.tar.gz
#cd nload-0.7.2
#./configure
#make && make install
#cd ..
#rm -rf nload-0.7.2

#chkconfig services
for service in `chkconfig --list|awk '{print $1}'|egrep -v "^$"|awk -F ":" '{print $1}'`; do chkconfig $service off;done
for service in  ntpd crond sshd syslog rsyslog network irqbalance postfix; do chkconfig $service on;done

#load modprobe
if [ $macrover -eq 6 ]
then
        for onefile in `ls -A  /etc/modprobe.d/* | grep -v blacklist`
        do
                cat $onefile | grep -v 'ip_conntrack' | grep -v 'nf_conntrack'> /tmp/mod.tmp
                cat /tmp/mod.tmp > $onefile
                rm -f /tmp/mod.tmp
        done
        touch /etc/modprobe.d/iptables.conf
        echo 'options nf_conntrack hashsize=60240' >> /etc/modprobe.d/iptables.conf
        cat /etc/modprobe.d/iptables.conf

else
        cat /etc/modprobe.conf | grep -v 'ip_conntrack'| grep -v 'nf_conntrack' > /tmp/mod.tmp
        echo 'options ip_conntrack hashsize=60240' >> /tmp/mod.tmp
        cat /tmp/mod.tmp > /etc/modprobe.conf
        rm -f /tmp/mod.tmp
fi

#hardware check

#set irq ----- need update
#cd /home/work/opshell/
#wget 'http://download.xxx/lvs_nic_set_irq_affinity.sh'
#sh /home/work/opshell/lvs_nic_set_irq_affinity.sh &
#grep "lvs_nic_set_irq_affinity.sh" /etc/rc3.d/S10network|| ( sed -i 's/touch \/var\/lock\/subsys\/network/sh \/home\/work\/opshell\/lvs_nic_set_irq_affinity.sh\n        touch \/var\/lock\/subsys\/network/g' /etc/rc3.d/S10network )

#others
#配置postfix
sed -i "s/inet_interfaces = localhost /inet_interfaces = all/g" /etc/postfix/main.cf
sed --in-place -e 's/id:5:initdefault/id:3:initdefault/g' /etc/inittab
cat /etc/inittab| grep ':initdefault'
sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config
sed -i 's/GSSAPIAuthentication yes/#GSSAPIAuthentication yes/' /etc/ssh/sshd_config
sed -i 's/GSSAPICleanupCredentials yes/#GSSAPICleanupCredentials yes/' /etc/ssh/sshd_config
echo 'UseDNS no' >> /etc/ssh/sshd_config
/etc/init.d/sshd restart
netstat  -nltp| grep ssh
. /root/.bashrc
echo "export TMOUT=3600000" >>/etc/profile
source /etc/profile
sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config
#关闭IPV6支持
echo 'NETWORKING_IPV6=no' >> /etc/sysconfig/network
/etc/init.d/iptables stop >/dev/null 2>&1
#防止rm对根目录的误操作
echo "alias rm='rm -i --preserve-root'" >> /root/.bashrc
echo "alias chgrp='chgrp --preserve-root'" >> /root/.bashrc
echo "alias chown='chown --preserve-root'" >> /root/.bashrc
echo "alias chmod='chmod --preserve-root'" >> /root/.bashrc
echo "alias vi='vim'" >>/root/.bashrc
