#!/bin/bash
#READING environment variables from config files
source ./config.txt

cat >> /etc/fstab << EOF
$LFS_DEV	$LFS	ext4	defaults	1	1
EOF
