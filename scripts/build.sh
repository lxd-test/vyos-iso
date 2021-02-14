#!/usr/bin/env bash

if [ -d /home/vagrant/vyos-build ]; then
  pushd /home/vagrant/vyos-build
  git checkout .
  git pull origin current
  popd
else
  git clone -b current https://github.com/vyos/vyos-build /home/vagrant/vyos-build
fi

KERNEL=`jq -r .kernel_version /home/vagrant/vyos-build/data/defaults.json`

pushd /home/vagrant/vyos-build/packages/linux-kernel
if [ -d linux ]; then
  pushd linux
  if [ "`git describe --exact-match --tags $(git log -n1 --pretty='%h')`" != "v${KERNEL}" ]; then
    git fetch origin "refs/tags/v${KERNEL}:refs/tags/v${KERNEL}"
    git checkout --force v${KERNEL}
  fi
  popd
else
  git clone https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git
  pushd linux
  git fetch origin "refs/tags/v${KERNEL}:refs/tags/v${KERNEL}"
  git checkout v${KERNEL}
  popd
fi

pushd /home/vagrant/vyos-build
./configure --architecture amd64 --build-by "kikitux@gmail.com"
patch /home/vagrant/vyos-build/packages/linux-kernel/x86_64_vyos_defconfig < /vagrant/config_btrfs.patch

pushd /home/vagrant/vyos-build/packages/linux-kernel/
bash -x ./build-kernel.sh
popd


