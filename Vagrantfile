# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "lxd-test/debian10"
  config.vm.define "vyos-builder"
  config.vm.provision "shell", path: "scripts/provision.sh"
end
