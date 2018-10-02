#!/bin/bash
set -ex

# Reading Config.txt
source ./config.txt

# Chapter 3

# Set LFS variable for root in the .bashrc and reload it
cat >> /root/.bashrc << EOF
export LFS=$LFS
EOF
source /root/.bashrc

# mount $LFS partition if not already (it must be in /etc/fstab)
if [ ! -d $LFS ]; then mkdir $LFS; fi
mount -a

# Create world writable directory...
mkdir -vp $LFS/sources
chmod -v a+wt $LFS/sources

# ...and download sources inside it
if [ ! -e $LFS/sources/download.done ]; then
wget --input-file=wget-list --continue --directory-prefix=$LFS/sources
touch $LFS/sources/download.done
fi
if [ ! -e $LFS/sources/md5sums ]; then cp md5sums $LFS/sources/; fi 
pushd $LFS/sources
md5sum -c md5sums
popd

# Chapter 4

# Creating the $LFS/tools directory
if [ ! -e $LFS/tools ]; then mkdir -v $LFS/tools; fi
ln -sfv $LFS/tools /

# Adding the LFS user. PASSWORD is "lfs"
groupadd lfs
useradd -s /bin/bash -g lfs -m -k /dev/null lfs
cat << EOF | passwd lfs
lfs
lfs
EOF
chown -v lfs $LFS/toos
chown -v lfs $LFS/sources
