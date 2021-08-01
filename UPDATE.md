# Update Files

```bash
curl -sL https://github.com/casjay-base/centos/raw/main/scripts/update.sh | bash -
wget https://github.com/pkmgr/centos/raw/main/lists/default.list -O /tmp/default-packages.txt
yum install -y $(cat /tmp/default-packages.txt) --skip-broken

UPDATE=yes bash -c "$(curl -LsS https://raw.githubusercontent.com/casjay-dotfiles/minimal/master/install.sh)"
```
