#!/bin/bash

# liwenming <liwenming1@kingsoft.com>
# 2014-08-19
# LANG=en_US.UTF-8

# 注意事项:
#+ 此脚本用于在金山云linux云主机上初始化数据盘，为了往后数据盘无损数据扩展，这里使用了LVM。

#====以下变量可以根据实际需要自行修改==========
BK="/dev/vdc"		# 数据盘或数据分区名称，支持多块盘或分区，须以空格分隔（如BK="/dev/vdc /dev/vdd"）
VG=vg1					# VG名称
LV=lv_data				# LV名称
MP=/home			        # 挂载点路径
FS_TYPE=ext3				# 文件系统
MO=defaults				# 挂载参数
# 定义用户和组
USR=work
GRP=work
USR_ID=10000
GRP_ID=10000
SHEL=/bin/bash
HOM=/home/${USR}
#====以上变量可以根据实际需要自行修改==========


# 判断是否将${BK}块设备做了LVM。
lvm_ld()
{
    FLAG_LD=1 
    for BK_S in ${BK}
    do
        LD=$(pvdisplay|grep "${BK_S}")
        if [ -z "${LD}" ]
        then
            FLAG_LD=0
        else 
            echo "The ${BK_S} is added to Physical volume." 
            exit ${FLAG_LD} 
        fi
    done
}

# 判断${BK}块设备是否已挂载
mnt_md()
{
    FLAG_MD=2 
    for BK_S in ${BK}
    do
        MD=$(df|grep "${BK_S}"|awk '{print $1}')
        if [ -z "${MD}" ]
        then
            FLAG_MD=0
        else
	    echo "The ${BK_S} is already mounted "
            exit ${FLAG_LD} 
        fi
    done
}

# 创建LVM逻辑卷
create_lvm()
{
   pvcreate ${BK}
   vgcreate ${VG} ${BK}
   VG_Total_PE=$(vgdisplay ${VG}|grep 'Total PE'|awk '{print $NF}')
   lvcreate -n ${LV} -l ${VG_Total_PE} ${VG}
   mkfs.${FS_TYPE} /dev/${VG}/${LV}
   LV_UUID=$(blkid |grep "${LV}" |awk '{print $2}'|awk -F'=' '{print $NF}'|sed -e 's/"//g')
}

# 挂载数据分区
mnt_lvm()
{
    if [ ! -d ${MP} ]
    then
        mkdir -p ${MP}
    fi
    FSTAB=/etc/fstab
    DATE=$(date "+%Y-%m-%d_%H-%M-%S")	# 格式化日期
    cp -a ${FSTAB} ${FSTAB}.BAK.${DATE}
    sed -i "/\\${MP}\>/d" /etc/fstab
    echo "UUID=${LV_UUID}       ${MP}   ${FS_TYPE}    ${MO}        0 0" >> ${FSTAB}
    mount -a
}

# 判断用户是否已创建
check_id()
{
    FLAG_ID=3 
if [ $(id -u ${USR} 2>/dev/null) -eq ${USR_ID} 2>/dev/null ]
then
    FLAG_ID=0
else
    echo "Please create groups ${GRP} GID is ${GRP_ID}"
    echo "Please create users ${USR} UID is ${USR_ID}"
    echo "# groupadd -g ${GRP_ID} ${GRP}"
    echo "# useradd -u ${USR_ID} -g ${GRP} -s ${SHEL} -d ${HOM} -m ${USR}"
    exit ${FLAG_ID}
fi
}

# 更改数据分区属主和属组
chw_own()
{
    chown -R ${USR}:${GRP} ${MP} 
}

# 最后操作
mk_ok()
{
    lvm_ld
    mnt_md
    chw_own
    df -h ${MP}
    ls -ld ${MP}
    if [ ${FLAG_LD} -eq ${FLAG_MD} ]
    then
        create_lvm
        mnt_lvm
        chw_own
        df -h ${MP}
        ls -ld ${MP}
    fi

}

if [ $(id -ur) -ne 0 ]
then
    echo " please run $0 as root."
    exit 1
else
    check_id
    if [ ${FLAG_ID} -eq 0 ]
    then
        mk_ok
        rm $0
    else
       exit ${FLAG_ID}
    fi
fi
