# vyos-iso
Vagrantfile to build a custom vyos

## clone

```
git clone https://github.com/lxd-test/vyos-iso.git
cd vyos-iso
```

## build
```
vagrant up
```

## stop vm
```
vagrant halt
```

## check assets
```
ls -al build/
```

## new run
On new startup, the vm will run the `build` script again.

```
vagrant up
```

## delete vm
```
vagrant destroy
```
