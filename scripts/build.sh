#!/usr/bin/env bash

# update or clone vyos-build
if [ -d /home/vagrant/vyos-build ]; then
  pushd /home/vagrant/vyos-build
  git checkout .
  git pull origin current
  popd
else
  git clone -b current https://github.com/vyos/vyos-build /home/vagrant/vyos-build
fi

pushd /home/vagrant/vyos-build
./configure --architecture amd64 --build-by "kikitux@gmail.com"
KERNEL=`jq -r .kernel_version /home/vagrant/vyos-build/data/defaults.json`

# clone linux
if [ ! -d /home/vagrant/vyos-build/packages/linux-kernel/linux ]; then
  git clone https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git /home/vagrant/vyos-build/packages/linux-kernel/linux
fi

# check for kernel packages
pushd /home/vagrant/vyos-build/packages/linux-kernel/
ls linux-headers-${KERNEL}-amd64-vyos_${KERNEL}-1_amd64.deb linux-image-${KERNEL}-amd64-vyos_${KERNEL}-1_amd64.deb linux-libc-dev_${KERNEL}-1_amd64.deb linux-tools-${KERNEL}-amd64-vyos_${KERNEL}-1_amd64.deb
if [ $? -ne 0 ]; then
  pushd /home/vagrant/vyos-build/packages/linux-kernel/linux

  # change to kernel version tag defined in defaults.json
  if [ "`git describe --exact-match --tags $(git log -n1 --pretty='%h')`" != "v${KERNEL}" ]; then
    git fetch origin "refs/tags/v${KERNEL}:refs/tags/v${KERNEL}"
    git checkout --force v${KERNEL}
  fi

  patch /home/vagrant/vyos-build/packages/linux-kernel/x86_64_vyos_defconfig < /vagrant/config_btrfs.patch
  pushd /home/vagrant/vyos-build/packages/linux-kernel
  bash -x ./build-kernel.sh 2> /vagrant/logs/build-kernel.err | tee /vagrant/logs/make-deb-pkg.log

  cp linux-headers-${KERNEL}-amd64-vyos_${KERNEL}-1_amd64.deb linux-image-${KERNEL}-amd64-vyos_${KERNEL}-1_amd64.deb linux-libc-dev_${KERNEL}-1_amd64.deb linux-tools-${KERNEL}-amd64-vyos_${KERNEL}-1_amd64.deb /vagrant/build/
  # delete old iso if present
  [ -f /home/vagrant/vyos-build/build/live-image-amd64.hybrid.iso ] && rm -f /home/vagrant/vyos-build/build/live-image-amd64.hybrid.iso

  popd
fi

# check for iso
if [ ! -f /home/vagrant/vyos-build/build/vyos-1.4-rolling-${KERNEL}-amd64.iso ] ; then
  pushd /home/vagrant/vyos-build
  sudo make iso 2> /vagrant/logs/make-iso.err | tee /vagrant/logs/make-iso.log
  cp -a /home/vagrant/vyos-build/build/live-image-amd64.hybrid.iso /home/vagrant/vyos-build/build/vyos-1.4-rolling-${KERNEL}-amd64.iso
  cp -a /home/vagrant/vyos-build/build/live-image-amd64.hybrid.iso /vagrant/build/vyos-1.4-rolling-${KERNEL}-amd64.iso
  popd
fi

# kernel packages
if [ ! -f /home/vagrant/vyos-build/packages/linux-kernel/linux-${KERNEL}-amd64-vyos_${KERNEL}.orig.tar.gz ]; then
  pushd /home/vagrant/vyos-build/packages/linux-kernel/linux/
  source ../kernel-vars
  make deb-pkg BUILD_TOOLS=1 LOCALVERSION=${KERNEL_SUFFIX} KDEB_PKGVERSION=${KERNEL_VERSION}-1 -j $(getconf _NPROCESSORS_ONLN) 2> /vagrant/make-deb-pkg.err | tee /vagrant/make-deb-pkg.log
  cp /home/vagrant/vyos-build/packages/linux-kernel/linux-${KERNEL}-amd64-vyos_${KERNEL}.orig.tar.gz /vagrant/build/
fi

