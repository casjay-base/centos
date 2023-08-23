# RHEL & Fedora Configuration  
  
Setup a base almalinux server with my system scripts

## Update the system

```shell
bash -c "$(curl -q -LSsf "https://github.com/casjay-base/centos/raw/main/root/.local/bin/fetch-repo-file")" && reboot
```

## Install scripts

```shell
[ ! -d  "/usr/local/share/CasjaysDev/scripts" ] && \
echo cloning "https://github.com/casjay-dotfiles/scripts >/usr/local/share/CasjaysDev/scripts" &&
sudo git clone -q https://github.com/casjay-dotfiles/scripts "/usr/local/share/CasjaysDev/scripts" && \
sudo /usr/local/share/CasjaysDev/scripts/install.sh && reboot
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
