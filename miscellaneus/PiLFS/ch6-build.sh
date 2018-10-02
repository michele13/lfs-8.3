#!/bin/bash
#
# PiLFS Build Script SVN-20180718 v1.0
# Builds chapters 6.7 - Raspberry Pi Linux API Headers to 6.77 - Vim
# http://www.intestinate.com/pilfs
#
# Optional parameteres below:

PARALLEL_JOBS=4                 # Number of parallel make jobs, 1 for RPi1 and 4 for RPi2 and RPi3 recommended.
LOCAL_TIMEZONE=Europe/London    # Use this timezone from /usr/share/zoneinfo/ to set /etc/localtime. See "6.9.2. Configuring Glibc".
GROFF_PAPER_SIZE=A4             # Use this default paper size for Groff. See "6.58. Groff-1.22.3".
INSTALL_OPTIONAL_DOCS=1         # Install optional documentation when given a choice?
INSTALL_ALL_LOCALES=0           # Install all glibc locales? By default only en_US.ISO-8859-1 and en_US.UTF-8 are installed.
INSTALL_SYSTEMD_DEPS=1          # Install optional systemd dependencies? (Attr, Acl, Libcap, Expat, XML::Parser, Intltool, libffi, Meson, Ninja, Python)

# End of optional parameters

set -o nounset
set -o errexit

function prebuild_sanity_check {
    if [[ $(whoami) != "root" ]] ; then
        echo "You should be running as root for chapter 6!"
        exit 1
    fi

    if ! [[ -d /sources ]] ; then
        echo "Can't find your sources directory! Did you forget to chroot?"
        exit 1
    fi

    if ! [[ -d /tools ]] ; then
        echo "Can't find your tools directory! Did you forget to chroot?"
        exit 1
    fi
}

function check_tarballs {
LIST_OF_TARBALLS="
rpi-4.14.y.tar.gz
man-pages-4.16.tar.xz
glibc-2.27.tar.xz
glibc-2.27-fhs-1.patch
tzdata2018e.tar.gz
zlib-1.2.11.tar.xz
file-5.33.tar.gz
readline-7.0.tar.gz
m4-1.4.18.tar.xz
bc-1.07.1.tar.gz
binutils-2.31.1.tar.xz
gmp-6.1.2.tar.xz
mpfr-4.0.1.tar.xz
mpc-1.1.0.tar.gz
gcc-8.1.0.tar.xz
gcc-5.3.0-rpi1-cpu-default.patch
gcc-5.3.0-rpi2-cpu-default.patch
gcc-5.3.0-rpi3-cpu-default.patch
bzip2-1.0.6.tar.gz
bzip2-1.0.6-install_docs-1.patch
pkg-config-0.29.2.tar.gz
ncurses-6.1.tar.gz
attr-2.4.48.tar.gz
acl-2.2.53.tar.gz
libcap-2.25.tar.xz
sed-4.5.tar.xz
shadow-4.6.tar.xz
psmisc-23.1.tar.xz
iana-etc-2.30.tar.bz2
bison-3.0.5.tar.xz
flex-2.6.4.tar.gz
grep-3.1.tar.xz
bash-4.4.18.tar.gz
libtool-2.4.6.tar.xz
gdbm-1.16.tar.gz
gperf-3.1.tar.gz
expat-2.2.5.tar.bz2
inetutils-1.9.4.tar.xz
perl-5.28.0.tar.xz
XML-Parser-2.44.tar.gz
intltool-0.51.0.tar.gz
autoconf-2.69.tar.xz
automake-1.16.1.tar.xz
xz-5.2.4.tar.xz
kmod-25.tar.xz
gettext-0.19.8.1.tar.xz
elfutils-0.173.tar.bz2
libffi-3.2.1.tar.gz
openssl-1.1.0h.tar.gz
Python-3.7.0.tar.xz
python-3.7.0-docs-html.tar.bz2
ninja-1.8.2.tar.gz
ninja-1.8.2-add_NINJAJOBS_var-1.patch
meson-0.47.1.tar.gz
procps-ng-3.3.15.tar.xz
e2fsprogs-1.44.3.tar.gz
coreutils-8.30.tar.xz
coreutils-8.30-i18n-1.patch
check-0.12.0.tar.gz
diffutils-3.6.tar.xz
gawk-4.2.1.tar.xz
findutils-4.6.0.tar.gz
groff-1.22.3.tar.gz
less-530.tar.gz
gzip-1.9.tar.xz
iproute2-4.17.0.tar.xz
kbd-2.0.4.tar.xz
kbd-2.0.4-backspace-1.patch
libpipeline-1.5.0.tar.gz
make-4.2.1.tar.bz2
patch-2.7.6.tar.xz
sysklogd-1.5.1.tar.gz
sysvinit-2.90.tar.xz
sysvinit-2.90-consolidated-1.patch
eudev-3.2.5.tar.gz
udev-lfs-20171102.tar.bz2
util-linux-2.32.1.tar.xz
man-db-2.8.3.tar.xz
tar-1.30.tar.xz
texinfo-6.5.tar.xz
vim-8.1.tar.bz2
master.tar.gz
"

for tarball in $LIST_OF_TARBALLS ; do
    if ! [[ -f /sources/$tarball ]] ; then
        echo "Can't find /sources/$tarball!"
        exit 1
    fi
done
}

function timer {
    if [[ $# -eq 0 ]]; then
        echo $(date '+%s')
    else
        local stime=$1
        etime=$(date '+%s')
        if [[ -z "$stime" ]]; then stime=$etime; fi
        dt=$((etime - stime))
        ds=$((dt % 60))
        dm=$(((dt / 60) % 60))
        dh=$((dt / 3600))
        printf '%02d:%02d:%02d' $dh $dm $ds
    fi
}

prebuild_sanity_check
check_tarballs

if [[ $(cat /proc/swaps | wc -l) == 1 ]] ; then
    echo -e "\nYou are almost certainly going to want to add some swap space before building!"
    echo -e "(See http://www.intestinate.com/pilfs/beyond.html#addswap for instructions)"
    echo -e "Continue without swap?"
    select yn in "Yes" "No"; do
        case $yn in
            Yes ) break;;
            No ) exit;;
        esac
    done
fi

echo -e "\nThis is your last chance to quit before we start building... continue?"
echo "(Note that if anything goes wrong during the build, the script will abort mission)"
select yn in "Yes" "No"; do
    case $yn in
        Yes ) break;;
        No ) exit;;
    esac
done

total_time=$(timer)

echo "# 6.7. Raspberry Pi Linux API Headers"
cd /sources
if ! [[ -d /sources/linux-rpi-4.14.y ]] ; then
    tar -zxf rpi-4.14.y.tar.gz
fi
cd linux-rpi-4.14.y
make mrproper
make INSTALL_HDR_PATH=dest headers_install
find dest/include \( -name .install -o -name ..install.cmd \) -delete
cp -rv dest/include/* /usr/include
cd /sources

echo "# 6.8. Man-pages-4.16"
tar -Jxf man-pages-4.16.tar.xz
cd man-pages-4.16
make install
cd /sources
rm -rf man-pages-4.16

echo "# 6.9. Glibc-2.27"
tar -Jxf glibc-2.27.tar.xz
cd glibc-2.27
patch -Np1 -i ../glibc-2.27-fhs-1.patch
ln -sfv /tools/lib/gcc /usr/lib
GCC_INCDIR=/usr/lib/gcc/$(gcc -dumpmachine)/8.1.0/include
rm -f /usr/include/limits.h
mkdir -v build
cd build
CC="gcc -isystem $GCC_INCDIR -isystem /usr/include" \
../configure --prefix=/usr                          \
             --disable-werror                       \
             --enable-kernel=3.2                    \
             --enable-stack-protector=strong        \
             libc_cv_slibdir=/lib
unset GCC_INCDIR
make -j $PARALLEL_JOBS
touch /etc/ld.so.conf
sed '/test-installation/s@$(PERL)@echo not running@' -i ../Makefile
make install
cp -v ../nscd/nscd.conf /etc/nscd.conf
mkdir -pv /var/cache/nscd
if [[ $INSTALL_ALL_LOCALES = 1 ]] ; then
    make localedata/install-locales
else
    mkdir -pv /usr/lib/locale
    localedef -i en_US -f ISO-8859-1 en_US
    localedef -i en_US -f UTF-8 en_US.UTF-8
fi
cat > /etc/nsswitch.conf << "EOF"
# Begin /etc/nsswitch.conf

passwd: files
group: files
shadow: files

hosts: files dns
networks: files

protocols: files
services: files
ethers: files
rpc: files

# End /etc/nsswitch.conf
EOF
tar -zxf ../../tzdata2018e.tar.gz
ZONEINFO=/usr/share/zoneinfo
mkdir -pv $ZONEINFO/{posix,right}
for tz in etcetera southamerica northamerica europe africa antarctica  \
          asia australasia backward pacificnew systemv; do
    zic -L /dev/null   -d $ZONEINFO       -y "sh yearistype.sh" ${tz}
    zic -L /dev/null   -d $ZONEINFO/posix -y "sh yearistype.sh" ${tz}
    zic -L leapseconds -d $ZONEINFO/right -y "sh yearistype.sh" ${tz}
done
cp -v zone.tab zone1970.tab iso3166.tab $ZONEINFO
zic -d $ZONEINFO -p America/New_York
unset ZONEINFO
if ! [[ -f /usr/share/zoneinfo/$LOCAL_TIMEZONE ]] ; then
    echo "Seems like your timezone won't work out. Defaulting to London. Either fix it yourself later or consider moving there :)"
    cp -v /usr/share/zoneinfo/Europe/London /etc/localtime
else
    cp -v /usr/share/zoneinfo/$LOCAL_TIMEZONE /etc/localtime
fi
cat > /etc/ld.so.conf << "EOF"
# Begin /etc/ld.so.conf
/usr/local/lib

EOF
cat >> /etc/ld.so.conf << "EOF"
# Add an include directory
include /etc/ld.so.conf.d/*.conf

EOF
mkdir -pv /etc/ld.so.conf.d
# Compatibility symlink for non ld-linux-armhf awareness
ln -sv ld-2.27.so /lib/ld-linux.so.3
cd /sources
rm -rf glibc-2.27

echo "# 6.10. Adjusting the Toolchain"
mv -v /tools/bin/{ld,ld-old}
mv -v /tools/$(gcc -dumpmachine)/bin/{ld,ld-old}
mv -v /tools/bin/{ld-new,ld}
ln -sv /tools/bin/ld /tools/$(gcc -dumpmachine)/bin/ld
gcc -dumpspecs | sed -e 's@/tools@@g'                   \
    -e '/\*startfile_prefix_spec:/{n;s@.*@/usr/lib/ @}' \
    -e '/\*cpp:/{n;s@$@ -isystem /usr/include@}' >      \
    `dirname $(gcc --print-libgcc-file-name)`/specs

echo "# 6.11. Zlib-1.2.11"
tar -Jxf zlib-1.2.11.tar.xz
cd zlib-1.2.11
./configure --prefix=/usr
make -j $PARALLEL_JOBS
make install
mv -v /usr/lib/libz.so.* /lib
ln -sfv ../../lib/$(readlink /usr/lib/libz.so) /usr/lib/libz.so
cd /sources
rm -rf zlib-1.2.11

echo "# 6.12. File-5.33"
tar -zxf file-5.33.tar.gz
cd file-5.33
./configure --prefix=/usr
make -j $PARALLEL_JOBS
make install
cd /sources
rm -rf file-5.33

echo "# 6.13. Readline-7.0"
tar -zxf readline-7.0.tar.gz
cd readline-7.0
sed -i '/MV.*old/d' Makefile.in
sed -i '/{OLDSUFF}/c:' support/shlib-install
./configure --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/readline-7.0
make -j $PARALLEL_JOBS SHLIB_LIBS="-L/tools/lib -lncursesw"
make SHLIB_LIBS="-L/tools/lib -lncurses" install
mv -v /usr/lib/lib{readline,history}.so.* /lib
ln -sfv ../../lib/$(readlink /usr/lib/libreadline.so) /usr/lib/libreadline.so
ln -sfv ../../lib/$(readlink /usr/lib/libhistory.so ) /usr/lib/libhistory.so
if [[ $INSTALL_OPTIONAL_DOCS = 1 ]] ; then
    install -v -m644 doc/*.{ps,pdf,html,dvi} /usr/share/doc/readline-7.0
fi
cd /sources
rm -rf readline-7.0

echo "# 6.14. M4-1.4.18"
tar -Jxf m4-1.4.18.tar.xz
cd m4-1.4.18
./configure --prefix=/usr
make -j $PARALLEL_JOBS
make install
cd /sources
rm -rf m4-1.4.18

echo "# 6.15. Bc-1.07.1"
tar -zxf bc-1.07.1.tar.gz
cd bc-1.07.1
cat > bc/fix-libmath_h << "EOF"
#! /bin/bash
sed -e '1   s/^/{"/' \
    -e     's/$/",/' \
    -e '2,$ s/^/"/'  \
    -e   '$ d'       \
    -i libmath.h

sed -e '$ s/$/0}/' \
    -i libmath.h
EOF
ln -sv /tools/lib/libncursesw.so.6 /usr/lib/libncursesw.so.6
ln -sfv libncurses.so.6 /usr/lib/libncurses.so
sed -i -e '/flex/s/as_fn_error/: ;; # &/' configure
./configure --prefix=/usr           \
            --with-readline         \
            --mandir=/usr/share/man \
            --infodir=/usr/share/info
make -j $PARALLEL_JOBS
make install
cd /sources
rm -rf bc-1.07.1

echo "# 6.16. Binutils-2.31.1"
tar -Jxf binutils-2.31.1.tar.xz
cd binutils-2.31.1
mkdir -v build
cd build
../configure --prefix=/usr       \
             --enable-gold       \
             --enable-ld=default \
             --enable-plugins    \
             --enable-shared     \
             --disable-werror    \
             --enable-64-bit-bfd \
             --with-system-zlib
# Compiling gold chokes on parallel jobs
make tooldir=/usr
make tooldir=/usr install
cd /sources
rm -rf binutils-2.31.1

echo "# 6.17. GMP-6.1.2"
tar -Jxf gmp-6.1.2.tar.xz
cd gmp-6.1.2
./configure --prefix=/usr    \
            --enable-cxx     \
            --disable-static \
            --docdir=/usr/share/doc/gmp-6.1.2
make -j $PARALLEL_JOBS
make install
if [[ $INSTALL_OPTIONAL_DOCS = 1 ]] ; then
    make html
    make install-html
fi
cd /sources
rm -rf gmp-6.1.2

echo "# 6.18. MPFR-4.0.1"
tar -Jxf mpfr-4.0.1.tar.xz
cd mpfr-4.0.1
./configure  --prefix=/usr        \
             --disable-static     \
             --enable-thread-safe \
             --docdir=/usr/share/doc/mpfr-4.0.1
make -j $PARALLEL_JOBS
make install
if [[ $INSTALL_OPTIONAL_DOCS = 1 ]] ; then
    make html
    make install-html
fi
cd /sources
rm -rf mpfr-4.0.1

echo "# 6.19. MPC-1.1.0"
tar -zxf mpc-1.1.0.tar.gz
cd mpc-1.1.0
./configure --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/mpc-1.1.0
make -j $PARALLEL_JOBS
make install
if [[ $INSTALL_OPTIONAL_DOCS = 1 ]] ; then
    make html
    make install-html
fi
cd /sources
rm -rf mpc-1.1.0

echo "# 6.20. GCC-8.1.0"
tar -Jxf gcc-8.1.0.tar.xz
cd gcc-8.1.0
case $(uname -m) in
  armv6l) patch -Np1 -i ../gcc-5.3.0-rpi1-cpu-default.patch ;;
  armv7l) case $(sed -n '/^Revision/s/^.*: \(.*\)/\1/p' < /proc/cpuinfo) in
    a02082|a22082|a32082|a020d3) patch -Np1 -i ../gcc-5.3.0-rpi3-cpu-default.patch ;;
    *) patch -Np1 -i ../gcc-5.3.0-rpi2-cpu-default.patch ;;
    esac
  ;;
esac
rm -f /usr/lib/gcc
mkdir -v build
cd build
SED=sed                               \
../configure --prefix=/usr            \
             --enable-languages=c,c++ \
             --disable-multilib       \
             --disable-bootstrap      \
             --with-system-zlib
make
make install
ln -sv ../usr/bin/cpp /lib
ln -sv gcc /usr/bin/cc
install -v -dm755 /usr/lib/bfd-plugins
ln -sfv ../../libexec/gcc/$(gcc -dumpmachine)/8.1.0/liblto_plugin.so /usr/lib/bfd-plugins/
mkdir -pv /usr/share/gdb/auto-load/usr/lib
mv -v /usr/lib/*gdb.py /usr/share/gdb/auto-load/usr/lib
cd /sources
rm -rf gcc-8.1.0

echo "# 6.21. Bzip2-1.0.6"
tar -zxf bzip2-1.0.6.tar.gz
cd bzip2-1.0.6
patch -Np1 -i ../bzip2-1.0.6-install_docs-1.patch
sed -i 's@\(ln -s -f \)$(PREFIX)/bin/@\1@' Makefile
sed -i "s@(PREFIX)/man@(PREFIX)/share/man@g" Makefile
make -j $PARALLEL_JOBS -f Makefile-libbz2_so
make clean
make -j $PARALLEL_JOBS
make PREFIX=/usr install
cp -v bzip2-shared /bin/bzip2
cp -av libbz2.so* /lib
ln -sv ../../lib/libbz2.so.1.0 /usr/lib/libbz2.so
rm -v /usr/bin/{bunzip2,bzcat,bzip2}
ln -sv bzip2 /bin/bunzip2
ln -sv bzip2 /bin/bzcat
cd /sources
rm -rf bzip2-1.0.6

echo "# 6.22. Pkg-config-0.29.2"
tar -zxf pkg-config-0.29.2.tar.gz
cd pkg-config-0.29.2
./configure --prefix=/usr              \
            --with-internal-glib       \
            --disable-host-tool        \
            --docdir=/usr/share/doc/pkg-config-0.29.2
make -j $PARALLEL_JOBS
make install
cd /sources
rm -rf pkg-config-0.29.2

echo "# 6.23. Ncurses-6.1"
tar -zxf ncurses-6.1.tar.gz
cd ncurses-6.1
sed -i '/LIBTOOL_INSTALL/d' c++/Makefile.in
./configure --prefix=/usr           \
            --mandir=/usr/share/man \
            --with-shared           \
            --without-debug         \
            --without-normal        \
            --enable-pc-files       \
            --enable-widec
make -j $PARALLEL_JOBS
make install
mv -v /usr/lib/libncursesw.so.6* /lib
ln -sfv ../../lib/$(readlink /usr/lib/libncursesw.so) /usr/lib/libncursesw.so
for lib in ncurses form panel menu ; do
    rm -vf                    /usr/lib/lib${lib}.so
    echo "INPUT(-l${lib}w)" > /usr/lib/lib${lib}.so
    ln -sfv ${lib}w.pc        /usr/lib/pkgconfig/${lib}.pc
done
rm -vf                     /usr/lib/libcursesw.so
echo "INPUT(-lncursesw)" > /usr/lib/libcursesw.so
ln -sfv libncurses.so      /usr/lib/libcurses.so
if [[ $INSTALL_OPTIONAL_DOCS = 1 ]] ; then
    mkdir -v       /usr/share/doc/ncurses-6.1
    cp -v -R doc/* /usr/share/doc/ncurses-6.1
fi
cd /sources
rm -rf ncurses-6.1

if [[ $INSTALL_SYSTEMD_DEPS = 1 ]] ; then
echo "6.24. Attr-2.4.48"
tar -zxf attr-2.4.48.tar.gz
cd attr-2.4.48
./configure --prefix=/usr     \
            --bindir=/bin     \
            --disable-static  \
            --sysconfdir=/etc \
            --docdir=/usr/share/doc/attr-2.4.48
make -j $PARALLEL_JOBS
make install
mv -v /usr/lib/libattr.so.* /lib
ln -sfv ../../lib/$(readlink /usr/lib/libattr.so) /usr/lib/libattr.so
cd /sources
rm -rf attr-2.4.48
fi

if [[ $INSTALL_SYSTEMD_DEPS = 1 ]] ; then
echo "6.25. Acl-2.2.53"
tar -zxf acl-2.2.53.tar.gz
cd acl-2.2.53
./configure --prefix=/usr         \
            --bindir=/bin         \
            --disable-static      \
            --libexecdir=/usr/lib \
            --docdir=/usr/share/doc/acl-2.2.53
make -j $PARALLEL_JOBS
make install
mv -v /usr/lib/libacl.so.* /lib
ln -sfv ../../lib/$(readlink /usr/lib/libacl.so) /usr/lib/libacl.so
cd /sources
rm -rf acl-2.2.53
fi

if [[ $INSTALL_SYSTEMD_DEPS = 1 ]] ; then
echo "6.26. Libcap-2.25"
tar -Jxf libcap-2.25.tar.xz
cd libcap-2.25
sed -i '/install.*STALIBNAME/d' libcap/Makefile
make -j $PARALLEL_JOBS
make RAISE_SETFCAP=no lib=lib prefix=/usr install
chmod -v 755 /usr/lib/libcap.so
mv -v /usr/lib/libcap.so.* /lib
ln -sfv ../../lib/$(readlink /usr/lib/libcap.so) /usr/lib/libcap.so
cd /sources
rm -rf libcap-2.25
fi

echo "# 6.27. Sed-4.5"
tar -Jxf sed-4.5.tar.xz
cd sed-4.5
sed -i 's/usr/tools/'                 build-aux/help2man
sed -i 's/testsuite.panic-tests.sh//' Makefile.in
./configure --prefix=/usr --bindir=/bin
make -j $PARALLEL_JOBS
make install
if [[ $INSTALL_OPTIONAL_DOCS = 1 ]] ; then
    make html
    install -d -m755           /usr/share/doc/sed-4.5
    install -m644 doc/sed.html /usr/share/doc/sed-4.5
fi
cd /sources
rm -rf sed-4.5

echo "# 6.28. Shadow-4.6"
tar -Jxf shadow-4.6.tar.xz
cd shadow-4.6
sed -i 's/groups$(EXEEXT) //' src/Makefile.in
find man -name Makefile.in -exec sed -i 's/groups\.1 / /'   {} \;
find man -name Makefile.in -exec sed -i 's/getspnam\.3 / /' {} \;
find man -name Makefile.in -exec sed -i 's/passwd\.5 / /'   {} \;
sed -i -e 's@#ENCRYPT_METHOD DES@ENCRYPT_METHOD SHA512@' \
       -e 's@/var/spool/mail@/var/mail@' etc/login.defs
sed -i 's/1000/999/' etc/useradd
./configure --sysconfdir=/etc --with-group-name-max-length=32
make -j $PARALLEL_JOBS
make install
mv -v /usr/bin/passwd /bin
pwconv
grpconv
sed -i 's/yes/no/' /etc/default/useradd
# passwd root
# Root password will be set at the end of the script to prevent a stop here
cd /sources
rm -rf shadow-4.6

echo "# 6.29. Psmisc-23.1"
tar -Jxf psmisc-23.1.tar.xz
cd psmisc-23.1
./configure --prefix=/usr
make -j $PARALLEL_JOBS
make install
mv -v /usr/bin/fuser   /bin
mv -v /usr/bin/killall /bin
cd /sources
rm -rf psmisc-23.1

echo "# 6.30. Iana-Etc-2.30"
tar -jxf iana-etc-2.30.tar.bz2
cd iana-etc-2.30
make -j $PARALLEL_JOBS
make install
cd /sources
rm -rf iana-etc-2.30

echo "# 6.31. Bison-3.0.5"
tar -Jxf bison-3.0.5.tar.xz
cd bison-3.0.5
./configure --prefix=/usr --docdir=/usr/share/doc/bison-3.0.5
make -j $PARALLEL_JOBS
make install
cd /sources
rm -rf bison-3.0.5

echo "# 6.32. Flex-2.6.4"
tar -zxf flex-2.6.4.tar.gz
cd flex-2.6.4
sed -i "/math.h/a #include <malloc.h>" src/flexdef.h
HELP2MAN=/tools/bin/true ./configure --prefix=/usr --docdir=/usr/share/doc/flex-2.6.4
make -j $PARALLEL_JOBS
make install
ln -sv flex /usr/bin/lex
cd /sources
rm -rf flex-2.6.4

echo "# 6.33. Grep-3.1"
tar -Jxf grep-3.1.tar.xz
cd grep-3.1
./configure --prefix=/usr --bindir=/bin
make -j $PARALLEL_JOBS
make install
cd /sources
rm -rf grep-3.1

echo "# 6.34. Bash-4.4.18"
tar -zxf bash-4.4.18.tar.gz
cd bash-4.4.18
./configure --prefix=/usr                       \
            --docdir=/usr/share/doc/bash-4.4.18 \
            --without-bash-malloc               \
            --with-installed-readline
make -j $PARALLEL_JOBS
make install
mv -vf /usr/bin/bash /bin
# exec /bin/bash --login +h
# Don't know of a good way to keep running the script after entering bash here.
cd /sources
rm -rf bash-4.4.18

echo "# 6.35. Libtool-2.4.6"
tar -Jxf libtool-2.4.6.tar.xz
cd libtool-2.4.6
./configure --prefix=/usr
make -j $PARALLEL_JOBS
make install
cd /sources
rm -rf libtool-2.4.6

echo "# 6.36. GDBM-1.16"
tar -zxf gdbm-1.16.tar.gz
cd gdbm-1.16
./configure --prefix=/usr \
            --disable-static \
            --enable-libgdbm-compat
make -j $PARALLEL_JOBS
make install
cd /sources
rm -rf gdbm-1.16

echo "6.37. Gperf-3.1"
tar -zxf gperf-3.1.tar.gz
cd gperf-3.1
./configure --prefix=/usr --docdir=/usr/share/doc/gperf-3.1
make -j $PARALLEL_JOBS
make install
cd /sources
rm -rf gperf-3.1

if [[ $INSTALL_SYSTEMD_DEPS = 1 ]] ; then
echo "6.38. Expat-2.2.5"
tar -jxf expat-2.2.5.tar.bz2
cd expat-2.2.5
sed -i 's|usr/bin/env |bin/|' run.sh.in
./configure --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/expat-2.2.5
make -j $PARALLEL_JOBS
make install
if [[ $INSTALL_OPTIONAL_DOCS = 1 ]] ; then
    install -v -m644 doc/*.{html,png,css} /usr/share/doc/expat-2.2.5
fi
cd /sources
rm -rf expat-2.2.5
fi

echo "# 6.39. Inetutils-1.9.4"
tar -Jxf inetutils-1.9.4.tar.xz
cd inetutils-1.9.4
./configure --prefix=/usr        \
            --localstatedir=/var \
            --disable-logger     \
            --disable-whois      \
            --disable-rcp        \
            --disable-rexec      \
            --disable-rlogin     \
            --disable-rsh        \
            --disable-servers
make -j $PARALLEL_JOBS
make install
mv -v /usr/bin/{hostname,ping,ping6,traceroute} /bin
mv -v /usr/bin/ifconfig /sbin
cd /sources
rm -rf inetutils-1.9.4

echo "# 6.40. Perl-5.28.0"
tar -Jxf perl-5.28.0.tar.xz
cd perl-5.28.0
echo "127.0.0.1 localhost $(hostname)" > /etc/hosts
export BUILD_ZLIB=False
export BUILD_BZIP2=0
sh Configure -des -Dprefix=/usr                 \
                  -Dvendorprefix=/usr           \
                  -Dman1dir=/usr/share/man/man1 \
                  -Dman3dir=/usr/share/man/man3 \
                  -Dpager="/usr/bin/less -isR"  \
                  -Duseshrplib                  \
                  -Dusethreads
make -j $PARALLEL_JOBS
make install
unset BUILD_ZLIB BUILD_BZIP2
cd /sources
rm -rf perl-5.28.0

if [[ $INSTALL_SYSTEMD_DEPS = 1 ]] ; then
echo "6.41. XML::Parser-2.44"
tar -zxf XML-Parser-2.44.tar.gz
cd XML-Parser-2.44
perl Makefile.PL
make -j $PARALLEL_JOBS
make install
cd /sources
rm -rf XML-Parser-2.44
fi

if [[ $INSTALL_SYSTEMD_DEPS = 1 ]] ; then
echo "6.42. Intltool-0.51.0"
tar -zxf intltool-0.51.0.tar.gz
cd intltool-0.51.0
sed -i 's:\\\${:\\\$\\{:' intltool-update.in
./configure --prefix=/usr
make -j $PARALLEL_JOBS
make install
if [[ $INSTALL_OPTIONAL_DOCS = 1 ]] ; then
    install -v -Dm644 doc/I18N-HOWTO /usr/share/doc/intltool-0.51.0/I18N-HOWTO
fi
cd /sources
rm -rf intltool-0.51.0
fi

echo "# 6.43. Autoconf-2.69"
tar -Jxf autoconf-2.69.tar.xz
cd autoconf-2.69
./configure --prefix=/usr
make -j $PARALLEL_JOBS
make install
cd /sources
rm -rf autoconf-2.69

echo "# 6.44. Automake-1.16.1"
tar -Jxf automake-1.16.1.tar.xz
cd automake-1.16.1
./configure --prefix=/usr --docdir=/usr/share/doc/automake-1.16.1
make -j $PARALLEL_JOBS
make install
cd /sources
rm -rf automake-1.16.1

echo "# 6.45. Xz-5.2.4"
tar -Jxf xz-5.2.4.tar.xz
cd xz-5.2.4
./configure --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/xz-5.2.4
make -j $PARALLEL_JOBS
make install
mv -v /usr/bin/{lzma,unlzma,lzcat,xz,unxz,xzcat} /bin
mv -v /usr/lib/liblzma.so.* /lib
ln -svf ../../lib/$(readlink /usr/lib/liblzma.so) /usr/lib/liblzma.so
cd /sources
rm -rf xz-5.2.4

echo "# 6.46. kmod-25"
tar -Jxf kmod-25.tar.xz
cd kmod-25
./configure --prefix=/usr          \
            --bindir=/bin          \
            --sysconfdir=/etc      \
            --with-rootlibdir=/lib \
            --with-xz              \
            --with-zlib
make -j $PARALLEL_JOBS
make install
for target in depmod insmod lsmod modinfo modprobe rmmod; do
  ln -sv ../bin/kmod /sbin/$target
done
ln -sv kmod /bin/lsmod
cd /sources
rm -rf kmod-25

echo "# 6.47. Gettext-0.19.8.1"
tar -Jxf gettext-0.19.8.1.tar.xz
cd gettext-0.19.8.1
sed -i '/^TESTS =/d' gettext-runtime/tests/Makefile.in &&
sed -i 's/test-lock..EXEEXT.//' gettext-tools/gnulib-tests/Makefile.in
sed -e '/AppData/{N;N;p;s/\.appdata\./.metainfo./}' -i gettext-tools/its/appdata.loc
./configure --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/gettext-0.19.8.1
make -j $PARALLEL_JOBS
make install
chmod -v 0755 /usr/lib/preloadable_libintl.so
cd /sources
rm -rf gettext-0.19.8.1

echo "6.48. Libelf 0.173"
tar -jxf elfutils-0.173.tar.bz2
cd elfutils-0.173
./configure --prefix=/usr
make -j $PARALLEL_JOBS
make -C libelf install
install -vm644 config/libelf.pc /usr/lib/pkgconfig
cd /sources
rm -rf elfutils-0.173

if [[ $INSTALL_SYSTEMD_DEPS = 1 ]] ; then
echo "6.49. libffi-3.2.1"
tar -zxf libffi-3.2.1.tar.gz
cd libffi-3.2.1
sed -e '/^includesdir/ s/$(libdir).*$/$(includedir)/' -i include/Makefile.in
sed -e '/^includedir/ s/=.*$/=@includedir@/' -e 's/^Cflags: -I${includedir}/Cflags:/' -i libffi.pc.in
./configure --prefix=/usr --disable-static --with-gcc-arch=native
make -j $PARALLEL_JOBS
make install 
cd /sources
rm -rf libffi-3.2.1
fi

echo "6.50. OpenSSL-1.1.0h"
tar -zxf openssl-1.1.0h.tar.gz
cd openssl-1.1.0h
./config --prefix=/usr         \
         --openssldir=/etc/ssl \
         --libdir=lib          \
         shared                \
         zlib-dynamic
make -j $PARALLEL_JOBS
sed -i '/INSTALL_LIBS/s/libcrypto.a libssl.a//' Makefile
make MANSUFFIX=ssl install
if [[ $INSTALL_OPTIONAL_DOCS = 1 ]] ; then
    mv -v /usr/share/doc/openssl /usr/share/doc/openssl-1.1.0h
    cp -vfr doc/* /usr/share/doc/openssl-1.1.0h
fi
cd /sources
rm -rf openssl-1.1.0h

if [[ $INSTALL_SYSTEMD_DEPS = 1 ]] ; then
echo "6.51. Python-3.7.0"
tar -Jxf Python-3.7.0.tar.xz
cd Python-3.7.0
./configure --prefix=/usr       \
            --enable-shared     \
            --with-system-expat \
            --with-system-ffi   \
            --with-ensurepip=yes
make -j $PARALLEL_JOBS
make install 
chmod -v 755 /usr/lib/libpython3.7m.so
chmod -v 755 /usr/lib/libpython3.so
if [[ $INSTALL_OPTIONAL_DOCS = 1 ]] ; then
    install -v -dm755 /usr/share/doc/python-3.7.0/html
    tar --strip-components=1 --no-same-owner --no-same-permissions -C /usr/share/doc/python-3.7.0/html -jxf ../python-3.7.0-docs-html.tar.bz2
fi
cd /sources
rm -rf Python-3.7.0
fi

if [[ $INSTALL_SYSTEMD_DEPS = 1 ]] ; then
echo "6.52. Ninja-1.8.2"
tar -zxf ninja-1.8.2.tar.gz
cd ninja-1.8.2
patch -Np1 -i ../ninja-1.8.2-add_NINJAJOBS_var-1.patch
python3 configure.py --bootstrap
install -vm755 ninja /usr/bin/
install -vDm644 misc/bash-completion /usr/share/bash-completion/completions/ninja
install -vDm644 misc/zsh-completion /usr/share/zsh/site-functions/_ninja
cd /sources
rm -rf ninja-1.8.2
fi

if [[ $INSTALL_SYSTEMD_DEPS = 1 ]] ; then
echo "6.53. Meson-0.47.1"
tar -zxf meson-0.47.1.tar.gz
cd meson-0.47.1
python3 setup.py build
python3 setup.py install --root=dest
cp -rv dest/* /
cd /sources
rm -rf meson-0.47.1
fi

echo "# 6.54. Procps-ng-3.3.15"
tar -Jxf procps-ng-3.3.15.tar.xz
cd procps-ng-3.3.15
./configure --prefix=/usr                            \
            --exec-prefix=                           \
            --libdir=/usr/lib                        \
            --docdir=/usr/share/doc/procps-ng-3.3.15 \
            --disable-static                         \
            --disable-kill
make -j $PARALLEL_JOBS
make install
mv -v /usr/lib/libprocps.so.* /lib
ln -sfv ../../lib/$(readlink /usr/lib/libprocps.so) /usr/lib/libprocps.so
cd /sources
rm -rf procps-ng-3.3.15

echo "# 6.55. E2fsprogs-1.44.3"
tar -zxf e2fsprogs-1.44.3.tar.gz
cd e2fsprogs-1.44.3
mkdir -v build
cd build
../configure --prefix=/usr           \
             --bindir=/bin           \
             --with-root-prefix=""   \
             --enable-elf-shlibs     \
             --disable-libblkid      \
             --disable-libuuid       \
             --disable-uuidd         \
             --disable-fsck
make -j $PARALLEL_JOBS
make install
make install-libs
chmod -v u+w /usr/lib/{libcom_err,libe2p,libext2fs,libss}.a
if [[ $INSTALL_OPTIONAL_DOCS = 1 ]] ; then
    gunzip -v /usr/share/info/libext2fs.info.gz
    install-info --dir-file=/usr/share/info/dir /usr/share/info/libext2fs.info
    makeinfo -o      doc/com_err.info ../lib/et/com_err.texinfo
    install -v -m644 doc/com_err.info /usr/share/info
    install-info --dir-file=/usr/share/info/dir /usr/share/info/com_err.info
fi
cd /sources
rm -rf e2fsprogs-1.44.3

echo "# 6.56. Coreutils-8.30"
tar -Jxf coreutils-8.30.tar.xz
cd coreutils-8.30
patch -Np1 -i ../coreutils-8.30-i18n-1.patch
sed -i '/test.lock/s/^/#/' gnulib-tests/gnulib.mk
autoreconf -fiv
FORCE_UNSAFE_CONFIGURE=1 ./configure \
            --prefix=/usr            \
            --enable-no-install-program=kill,uptime
FORCE_UNSAFE_CONFIGURE=1 make -j $PARALLEL_JOBS
make install
mv -v /usr/bin/{cat,chgrp,chmod,chown,cp,date,dd,df,echo} /bin
mv -v /usr/bin/{false,ln,ls,mkdir,mknod,mv,pwd,rm} /bin
# Found a problem here where the moved mv binary from the line above can't be found by the next line.
# Inserting a sync as a workaround.
sync
mv -v /usr/bin/{rmdir,stty,sync,true,uname} /bin
mv -v /usr/bin/chroot /usr/sbin
mv -v /usr/share/man/man1/chroot.1 /usr/share/man/man8/chroot.8
sed -i s/\"1\"/\"8\"/1 /usr/share/man/man8/chroot.8
mv -v /usr/bin/{head,sleep,nice} /bin
cd /sources
rm -rf coreutils-8.30

echo "# 6.57. Check-0.12.0"
tar -zxf check-0.12.0.tar.gz
cd check-0.12.0
./configure --prefix=/usr
make -j $PARALLEL_JOBS
make install
sed -i '1 s/tools/usr/' /usr/bin/checkmk
cd /sources
rm -rf check-0.12.0

echo "# 6.58. Diffutils-3.6"
tar -Jxf diffutils-3.6.tar.xz
cd diffutils-3.6
./configure --prefix=/usr
make -j $PARALLEL_JOBS
make install
cd /sources
rm -rf diffutils-3.6

echo "# 6.59. Gawk-4.2.1"
tar -Jxf gawk-4.2.1.tar.xz
cd gawk-4.2.1
sed -i 's/extras//' Makefile.in
./configure --prefix=/usr
make -j $PARALLEL_JOBS
make install
if [[ $INSTALL_OPTIONAL_DOCS = 1 ]] ; then
    mkdir -v /usr/share/doc/gawk-4.2.1
    cp    -v doc/{awkforai.txt,*.{eps,pdf,jpg}} /usr/share/doc/gawk-4.2.1
fi
cd /sources
rm -rf gawk-4.2.1

echo "# 6.60. Findutils-4.6.0"
tar -zxf findutils-4.6.0.tar.gz
cd findutils-4.6.0
sed -i 's/test-lock..EXEEXT.//' tests/Makefile.in
./configure --prefix=/usr --localstatedir=/var/lib/locate
make -j $PARALLEL_JOBS
make install
mv -v /usr/bin/find /bin
sed -i 's/find:=${BINDIR}/find:=\/bin/' /usr/bin/updatedb
cd /sources
rm -rf findutils-4.6.0

echo "# 6.61. Groff-1.22.3"
tar -zxf groff-1.22.3.tar.gz
cd groff-1.22.3
PAGE=$GROFF_PAPER_SIZE ./configure --prefix=/usr
# Groff doesn't like parallel jobs
make -j 1
make install
cd /sources
rm -rf groff-1.22.3

# 6.62. GRUB-2.02~beta2
# We don't use GRUB on ARM

echo "# 6.63. Less-530"
tar -zxf less-530.tar.gz
cd less-530
./configure --prefix=/usr --sysconfdir=/etc
make -j $PARALLEL_JOBS
make install
cd /sources
rm -rf less-530

echo "# 6.64. Gzip-1.9"
tar -Jxf gzip-1.9.tar.xz
cd gzip-1.9
./configure --prefix=/usr
make -j $PARALLEL_JOBS
make install
mv -v /usr/bin/gzip /bin
cd /sources
rm -rf gzip-1.9

echo "# 6.65. IPRoute2-4.17.0"
tar -Jxf iproute2-4.17.0.tar.xz
cd iproute2-4.17.0
sed -i /ARPD/d Makefile
rm -fv man/man8/arpd.8
sed -i 's/m_ipt.o//' tc/Makefile
make -j $PARALLEL_JOBS
make DOCDIR=/usr/share/doc/iproute2-4.17.0 install
cd /sources
rm -rf iproute2-4.17.0

echo "# 6.66. Kbd-2.0.4"
tar -Jxf kbd-2.0.4.tar.xz
cd kbd-2.0.4
patch -Np1 -i ../kbd-2.0.4-backspace-1.patch
sed -i 's/\(RESIZECONS_PROGS=\)yes/\1no/g' configure
sed -i 's/resizecons.8 //' docs/man/man8/Makefile.in
PKG_CONFIG_PATH=/tools/lib/pkgconfig ./configure --prefix=/usr --disable-vlock
make -j $PARALLEL_JOBS
make install
if [[ $INSTALL_OPTIONAL_DOCS = 1 ]] ; then
    mkdir -v /usr/share/doc/kbd-2.0.4
    cp -R -v docs/doc/* /usr/share/doc/kbd-2.0.4
fi
cd /sources
rm -rf kbd-2.0.4

echo "# 6.67. Libpipeline-1.5.0"
tar -zxf libpipeline-1.5.0.tar.gz
cd libpipeline-1.5.0
./configure --prefix=/usr
make -j $PARALLEL_JOBS
make install
cd /sources
rm -rf libpipeline-1.5.0

echo "# 6.68 Make-4.2.1"
tar -jxf make-4.2.1.tar.bz2
cd make-4.2.1
sed -i '211,217 d; 219,229 d; 232 d' glob/glob.c
./configure --prefix=/usr
make -j $PARALLEL_JOBS
make install
cd /sources
rm -rf make-4.2.1

echo "# 6.69. Patch-2.7.6"
tar -Jxf patch-2.7.6.tar.xz
cd patch-2.7.6
./configure --prefix=/usr
make -j $PARALLEL_JOBS
make install
cd /sources
rm -rf patch-2.7.6

echo "# 6.70. Sysklogd-1.5.1"
tar -zxf sysklogd-1.5.1.tar.gz
cd sysklogd-1.5.1
sed -i '/Error loading kernel symbols/{n;n;d}' ksym_mod.c
sed -i 's/union wait/int/' syslogd.c
make -j $PARALLEL_JOBS
make BINDIR=/sbin install
cat > /etc/syslog.conf << "EOF"
# Begin /etc/syslog.conf

auth,authpriv.* -/var/log/auth.log
*.*;auth,authpriv.none -/var/log/sys.log
daemon.* -/var/log/daemon.log
kern.* -/var/log/kern.log
mail.* -/var/log/mail.log
user.* -/var/log/user.log
*.emerg *

# End /etc/syslog.conf
EOF
cd /sources
rm -rf sysklogd-1.5.1

echo "# 6.71. Sysvinit-2.90"
tar -Jxf sysvinit-2.90.tar.xz
cd sysvinit-2.90
patch -Np1 -i ../sysvinit-2.90-consolidated-1.patch
make -j $PARALLEL_JOBS -C src
make -C src install
cd /sources
rm -rf sysvinit-2.90

echo "# 6.72. Eudev-3.2.5"
tar -zxf eudev-3.2.5.tar.gz
cd eudev-3.2.5
cat > config.cache << "EOF"
HAVE_BLKID=1
BLKID_LIBS="-lblkid"
BLKID_CFLAGS="-I/tools/include"
EOF
./configure --prefix=/usr           \
            --bindir=/sbin          \
            --sbindir=/sbin         \
            --libdir=/usr/lib       \
            --sysconfdir=/etc       \
            --libexecdir=/lib       \
            --with-rootprefix=      \
            --with-rootlibdir=/lib  \
            --enable-manpages       \
            --disable-static        \
            --config-cache
LIBRARY_PATH=/tools/lib make -j $PARALLEL_JOBS
mkdir -pv /lib/udev/rules.d
mkdir -pv /etc/udev/rules.d
make LD_LIBRARY_PATH=/tools/lib install
tar -jxf ../udev-lfs-20171102.tar.bz2
make -f udev-lfs-20171102/Makefile.lfs install
LD_LIBRARY_PATH=/tools/lib udevadm hwdb --update
cd /sources
rm -rf eudev-3.2.5

echo "# 6.73. Util-linux-2.32.1"
tar -Jxf util-linux-2.32.1.tar.xz
cd util-linux-2.32.1
mkdir -pv /var/lib/hwclock
rm -vf /usr/include/{blkid,libmount,uuid}
./configure ADJTIME_PATH=/var/lib/hwclock/adjtime   \
            --docdir=/usr/share/doc/util-linux-2.32.1 \
            --disable-chfn-chsh  \
            --disable-login      \
            --disable-nologin    \
            --disable-su         \
            --disable-setpriv    \
            --disable-runuser    \
            --disable-pylibmount \
            --disable-static     \
            --without-python     \
            --without-systemd    \
            --without-systemdsystemunitdir
make -j $PARALLEL_JOBS
make install
cd /sources
rm -rf util-linux-2.32.1

echo "# 6.74. Man-DB-2.8.3"
tar -Jxf man-db-2.8.3.tar.xz
cd man-db-2.8.3
./configure --prefix=/usr                        \
            --docdir=/usr/share/doc/man-db-2.8.3 \
            --sysconfdir=/etc                    \
            --disable-setuid                     \
            --enable-cache-owner=bin             \
            --with-browser=/usr/bin/lynx         \
            --with-vgrind=/usr/bin/vgrind        \
            --with-grap=/usr/bin/grap            \
            --with-systemdtmpfilesdir=
make -j $PARALLEL_JOBS
make install
cd /sources
rm -rf man-db-2.8.3

echo "# 6.75. Tar-1.30"
tar -Jxf tar-1.30.tar.xz
cd tar-1.30
FORCE_UNSAFE_CONFIGURE=1  \
./configure --prefix=/usr \
            --bindir=/bin
make -j $PARALLEL_JOBS
make install
if [[ $INSTALL_OPTIONAL_DOCS = 1 ]] ; then
    make -C doc install-html docdir=/usr/share/doc/tar-1.30
fi
cd /sources
rm -rf tar-1.30

echo "# 6.76. Texinfo-6.5"
tar -Jxf texinfo-6.5.tar.xz
cd texinfo-6.5
sed -i '5481,5485 s/({/(\\{/' tp/Texinfo/Parser.pm
./configure --prefix=/usr --disable-static
make -j $PARALLEL_JOBS
make install
# I don't know anybody who wants this... prove me wrong!
# make TEXMF=/usr/share/texmf install-tex
cd /sources
rm -rf texinfo-6.5

echo "# 6.77. Vim-8.1"
tar -jxf vim-8.1.tar.bz2
cd vim81
echo '#define SYS_VIMRC_FILE "/etc/vimrc"' >> src/feature.h
./configure --prefix=/usr
make -j $PARALLEL_JOBS
make install
ln -sv vim /usr/bin/vi
for L in /usr/share/man/{,*/}man1/vim.1; do
    ln -sv vim.1 $(dirname $L)/vi.1
done
ln -sv ../vim/vim81/doc /usr/share/doc/vim-8.1
cat > /etc/vimrc << "EOF"
" Begin /etc/vimrc

" Ensure defaults are set before customizing settings, not after
source $VIMRUNTIME/defaults.vim
let skip_defaults_vim=1 

set nocompatible
set backspace=2
set mouse=
syntax on
if (&term == "xterm") || (&term == "putty")
  set background=dark
endif

" End /etc/vimrc
EOF
cd /sources
rm -rf vim81

echo -e "--------------------------------------------------------------------"
echo -e "\nYou made it! Now there are just a few things left to take care of..."
printf 'Total script time: %s\n' $(timer $total_time)
echo -e "\nYou have not set a root password yet. Go ahead, I'll wait here.\n"
passwd root

echo -e "\nNow about the firmware..."
echo "You probably want to copy the supplied Broadcom libraries to /opt/vc?"
select yn in "Yes" "No"; do
    case $yn in
        Yes ) tar -zxf master.tar.gz && cp -rv /sources/firmware-master/hardfp/opt/vc /opt && echo "/opt/vc/lib" >> /etc/ld.so.conf.d/broadcom.conf && ldconfig; break;;
        No ) break;;
    esac
done

echo -e "\nIf you're not going to compile your own kernel you probably want to copy the kernel modules from the firmware package to /lib/modules?"
select yn in "Yes" "No"; do
    case $yn in
        Yes ) cp -rv /sources/firmware-master/modules /lib; break;;
        No ) break;;
    esac
done

echo -e "\nLast question, if you want I can mount the boot partition and overwrite the kernel and bootloader with the one you downloaded?"
select yn in "Yes" "No"; do
    case $yn in
        Yes ) mount /dev/mmcblk0p1 /boot && cp -rv /sources/firmware-master/boot / && umount /boot; break;;
        No ) break;;
    esac
done

echo -e "\nThere, all done! Now continue reading from \"6.78. About Debugging Symbols\" to make your system bootable."
echo "And don't forget to check out http://www.intestinate.com/pilfs/beyond.html when you're done with your build!"
