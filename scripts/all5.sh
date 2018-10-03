#!/bin/bash
source ./config.txt
set -ex

TOP=$PWD
source $TOP/5.4-lfs_binutils-2.31.1-pass-1.script
source $TOP/5.5-lfs_gcc-8.2.0-pass-1.script
source $TOP/5.6-lfs_linux-4.18.5-api-headers.script
source $TOP/5.7-lfs_glibc-2.28.script
