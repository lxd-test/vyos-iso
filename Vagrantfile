# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "lxd-test/debian10"
  config.vm.define "vyos-builder"

  config.vm.provider "virtualbox" do |v|
    v.memory = 1024 * 4
    v.cpus = 4
    v.customize ["guestproperty", "set", :id, "/VirtualBox/GuestAdd/VBoxService/--timesync-set-threshold", "1000"]
  end

  config.vm.synced_folder "apt-cacher-ng", "/var/cache/apt-cacher-ng", owner: "root",  group: "root",
    mount_options: ["dmode=777,fmode=666"], create: "true"

  config.vm.provision "shell", path: "scripts/provision.sh"
  config.vm.provision "shell", path: "scripts/cache.sh", privileged: false, run: "always"
  config.vm.provision "shell", path: "scripts/build.sh", privileged: false, run: "always"
end
