#!/bin/bash
#READING environment variables from config files
source ./config.txt

cat >> /etc/fstab < EOF
$LFS_DEV	$LFS	defaults	1	1