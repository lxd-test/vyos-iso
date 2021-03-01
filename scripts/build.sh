#!/usr/bin/env bash

mkdir -p /vagrant/logs/ /vagrant/build/
exec 2>/vagrant/logs/build.err

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
pushd /vagrant/build/
ls linux-headers-${KERNEL}-amd64-vyos_${KERNEL}-1_amd64.deb linux-image-${KERNEL}-amd64-vyos_${KERNEL}-1_amd64.deb linux-libc-dev_${KERNEL}-1_amd64.deb linux-tools-${KERNEL}-amd64-vyos_${KERNEL}-1_amd64.deb
if [ $? -ne 0 ]; then

  # delete old kernel if present
  rm -f /home/vagrant/vyos-build/packages/linux-kernel/linux-* || true

  # we are building kernel, lets delete any leftover iso
  rm -f /home/vagrant/vyos-build/build/{live-image-amd64.*,*iso} || true
  rm -f /vagrant/build/vyos-*iso || true

  pushd /home/vagrant/vyos-build/packages/linux-kernel/linux

  # change to kernel version tag defined in defaults.json
  if [ "`git describe --exact-match --tags $(git log -n1 --pretty='%h')`" != "v${KERNEL}" ]; then
    git fetch origin "refs/tags/v${KERNEL}:refs/tags/v${KERNEL}"
    git checkout --force v${KERNEL}
  fi

  pushd /home/vagrant/vyos-build/packages/linux-kernel

  # add custom kernel configuration
  cp x86_64_vyos_defconfig .config
  ./linux/scripts/kconfig/merge_config.sh -m .config /vagrant/config_btrfs.fragment
  cp .config x86_64_vyos_defconfig

  bash -x ./build-kernel.sh

  cp linux-headers-${KERNEL}-amd64-vyos_${KERNEL}-1_amd64.deb linux-image-${KERNEL}-amd64-vyos_${KERNEL}-1_amd64.deb linux-libc-dev_${KERNEL}-1_amd64.deb linux-tools-${KERNEL}-amd64-vyos_${KERNEL}-1_amd64.deb /vagrant/build/

  popd
fi

# check for iso
if [ ! -f /vagrant/build/vyos-1.4-rolling-${KERNEL}-amd64.iso ] ; then
  pushd /home/vagrant/vyos-build
  # we building an iso, lets remove old images
  rm -f build/{live-image-amd64.*,*iso} || true
  sudo make iso
  cp -a /home/vagrant/vyos-build/build/live-image-amd64.hybrid.iso /vagrant/build/vyos-1.4-rolling-${KERNEL}-amd64.iso
  popd
fi

# kernel packages
if [ ! -f /vagrant/build/linux-${KERNEL}-amd64-vyos_${KERNEL}.orig.tar.gz ]; then
  pushd /home/vagrant/vyos-build/packages/linux-kernel/linux/
  source ../kernel-vars
  make deb-pkg BUILD_TOOLS=1 LOCALVERSION=${KERNEL_SUFFIX} KDEB_PKGVERSION=${KERNEL_VERSION}-1 -j $(getconf _NPROCESSORS_ONLN)
  cp /home/vagrant/vyos-build/packages/linux-kernel/linux-${KERNEL}-amd64-vyos_${KERNEL}.orig.tar.gz /vagrant/build/
fi

pushd /vagrant/build
shasum -a 256 linux-* vyos-*iso | tee SHA256SUMS

