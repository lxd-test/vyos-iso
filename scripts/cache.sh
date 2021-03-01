#!/usr/bin/env bash

export DEBIAN_FRONTEND=noninteractive

# apt-cacher-ng
dpkg -s apt-cacher-ng auto-apt-proxy || {
  sudo apt-get update
  sudo apt-get install -y apt-cacher-ng auto-apt-proxy 
  sudo sed -i -e 's/User=apt-cacher-ng/#User=apt-cacher-ng/g' -e 's/Group=apt-cacher-ng/#Group=apt-cacher-ng/g' /etc/systemd/system/multi-user.target.wants/apt-cacher-ng.service
  sudo systemctl daemon-reload
  sudo systemctl enable apt-cacher-ng
  sudo systemctl stop apt-cacher-ng
  sudo systemctl start apt-cacher-ng
}

# ccache
# Install package
which ccache 2>/dev/null || {
  sudo apt-get update
  sudo apt-get install -y ccache
}

# Update symlinks
sudo /usr/sbin/update-ccache-symlinks

# Prepend ccache into the PATH
grep ccache ~/.bashrc 2>/dev/null || {
  echo 'export PATH="/usr/lib/ccache:$PATH"' | tee -a ~/.bashrc
}

# Source bashrc to test the new PATH
source ~/.bashrc

# Prepend ccache into the PATH
grep ccache ~/.profile 2>/dev/null || {
  echo 'export PATH="/usr/lib/ccache:$PATH"' | tee -a ~/.profile
}

mkdir -p ~/.ccache/ /vagrant/ccache
tee > ~/.ccache/ccache.conf <<EOF
max_size = 0
max_files = 0
cache_dir = /vagrant/ccache
EOF

ccache -s
