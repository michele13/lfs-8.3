#!/bin/bash

# Reading Config.txt
source ./config.txt

# Chapter 3

# Set LFS variable for root in the .bashrc and reload it
cat >> /root/.bashrc < EOF
export LFS=$LFS
EOF
source /root/.bashrc

# mount $LFS partition if not already (it must be in /etc/fstab)
mount -a

# Create world writable directory...
mkdir -v $LFS/sources
chmod -v a+wt $LFS/sources

# ...and download sources inside it
wget --input-file=wget-list --continue --directory-prefix=$LFS/sources
pushd $LFS/sources
md5sum -c md5sums
popd

# Chapter 4

# Creating the $LFS/tools directory
mkdir -v $LFS/tools
ln -sv $LFS/tools /

# Adding the LFS user. PASSWORD is "lfs"
groupadd lfs
useradd -s /bin/bash -g lfs -m -k /dev/null lfs
cat << EOF | passwd lfs
lfs
EOF
