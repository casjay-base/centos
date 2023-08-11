# RHEL & Fedora Configuration  
  
Setup a base almalinux server

## Install scripts

```shell
sudo git clone https://github.com/casjay-dotfiles/scripts "/usr/local/share/CasjaysDev/scripts" && \
sudo /usr/local/share/CasjaysDev/scripts/install.sh
```

## Update the system

```shell
yum update -y
```

## Reboot the  system

```shell
reboot
```

## Automated Install  
  
```shell
sudo bash -c "$(curl -q -LSsf "https://github.com/pkmgr/centos/raw/main/scripts/min.sh")"
```

OR for oracle cloud almalinux

```shell
sudo bash -c "$(curl -q -LSsf "https://github.com/pkmgr/centos/raw/main/scripts/min.oci.sh")"
```
  
## Automated Update  

```shell
sudo bash -c "$(curl -q -LSsf "https://github.com/casjay-base/centos/raw/main/root/.local/bin/run-os-update")"
```
  
  
[![Patreon](https://img.shields.io/badge/patreon-donate-orange.svg)](https://www.patreon.com/casjay ) [![Paypal](https://img.shields.io/badge/Donate-PayPal-green.svg)](https://www.paypal.me/casjaysdev )
