# AlmaLinux  
  
Setup a base almalinux server with my system scripts

## Enable swap if system has than 2 gigs of memory

```shell
swap_file="os.swap"
swap_dir="/var/lib/swap"
kilobit="1000000"
mem="$(free|grep ':'|awk '{print $2}'|head -n1||echo "1")"
if [ $mem -le $kilobit ] && [ ! -f "$swap_dir/$swap_file" ]; then
  echo "Setting up swap in $swap_dir/$swap_file"
  echo "This may take a few minutes so enjoy your coffee"
  sudo mkdir -p "$swap_dir"
  if sudo dd if=/dev/zero of=$swap_dir/$swap_file bs=2048 count=1048576 >/dev/null; then
    sudo chmod 600 $swap_dir/$swap_file
    sudo mkswap $swap_dir/$swap_file
    sudo swapon $swap_dir/$swap_file
    if ! grep -qs "$swap_dir/$swap_file" /etc/fstab; then
      echo "$swap_dir/$swap_file          swap        swap             defaults          0 0" |sudo tee -a /etc/fstab >/dev/null
    fi
  fi
fi
```

## Change settings

```shell
hostnamectl set-hostname host
passwd
```

## Install vnstat and enable it

```shell
yum install -yy epel-release && yum install -y vnstat && systemctl enable --now vnstat && reboot
```

## Update Packages

```shell
rpm -ev --nodeps initscripts
yum update -y && \
yum -yy install initscripts net-tools && \
#yum install -y NetworkManager-initscripts-updown && \
reboot
```

## Install Packages

```shell
yum install -y git curl wget bash bash-completion glibc-all-langpacks
```

## Update the system

```shell
bash -c "$(curl -q -LSsf "https://github.com/casjay-base/centos/raw/main/root/.local/bin/fetch-repo-file")" && reboot
```

## install kernel

```shell
curl -q -LSsf "https://github.com/casjay-base/centos/raw/main/root/.local/bin/run-os-update" | bash -s -- --kernel-ml  && reboot

```

## Set PHP Version  

```shell
PHP_VER="7.4"
dnf module -y reset php
dnf module -y install php:remi-$PHP_VER
```

## Install php nginx apache

```shell
yum install -yy php-cli php-cgi php-fpm httpd nginx && reboot 
```

## Install scripts

```shell
[ ! -d  "/usr/local/share/CasjaysDev/scripts" ] && \
echo cloning "https://github.com/casjay-dotfiles/scripts >/usr/local/share/CasjaysDev/scripts" &&
sudo git clone -q https://github.com/casjay-dotfiles/scripts "/usr/local/share/CasjaysDev/scripts" && \
sudo /usr/local/share/CasjaysDev/scripts/install.sh && reboot
```

## Install your personal dotfiles

```shell
git clone -q "url_to_dotfiles" "$HOME/dotfiles_dir"
```

## Automated Install  
  
```shell
sudo bash -c "$(curl -q -LSsf "https://github.com/pkmgr/centos/raw/main/scripts/min.sh")"
```

  
## Automated Update  

```shell
sudo bash -c "$(curl -q -LSsf "https://github.com/casjay-base/centos/raw/main/root/.local/bin/run-os-update")"
```
  
  
[![Patreon](https://img.shields.io/badge/patreon-donate-orange.svg)](https://www.patreon.com/casjay ) [![Paypal](https://img.shields.io/badge/Donate-PayPal-green.svg)](https://www.paypal.me/casjaysdev )
