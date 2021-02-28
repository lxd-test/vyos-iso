#!/usr/bin/env bash

export DEBIAN_FRONTEND=noninteractive

# apt-cacher-ng
apt-get update
apt-get install -y apt-cacher-ng auto-apt-proxy 

# ccache
# Install package
which ccache 2>/dev/null || {
  apt-get update
  apt-get install -y ccache
}

# Update symlinks
/usr/sbin/update-ccache-symlinks

# Prepend ccache into the PATH
grep ccache ~/.bashrc 2>/dev/null || {
  echo 'export PATH="/usr/lib/ccache:$PATH"' | tee -a ~/.bashrc
}

# Source bashrc to test the new PATH
source ~/.bashrc

mkdir -p ~/.ccache/ /vagrant/ccache
cat > ~/.ccache/ccache.conf <<EOF
max_size = 0
max_files = 0
cache_dir = /vagrant/ccache
EOF
ccache -s
