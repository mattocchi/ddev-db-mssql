#!/bin/bash
#ddev-generated
# This script installs eMSSQL server. Contains some ddev-specific twaks:
# - doesn't add ondrej's repo because that's already added
# - doesn't source .bashrc because that will happen anyway.
# - doesn't restart Apache; it's not started at this point.
# - assumes it's being run under sudo anyway and doesn't use sudo or su or exit
# - tries to run apt update as few times as possible
# - Apache's mpm_event module is already disabled.
#   Those don't work well with Docker builds.

# Optional: Exit if already installed.
if php -m | grep sqlsrv; then
  exit
fi

# https://learn.microsoft.com/en-us/sql/connect/php/installation-tutorial-linux-mac?view=sql-server-2017#step-1-install-php-2
# Some of these packages will be redundant.
export DEBIAN_FRONTEND=noninteractive
# Install sqlsrv drivers.
export PHP_VERSIONS="php7.0 php7.1 php7.2 php7.3 php7.4 php8.0 php8.1"
# Note: Only works for PHP 7.0+.
export PHP_SUFFIXES="7.0 7.1 7.2 7.3 7.4 8.0 8.1"

# https://learn.microsoft.com/en-us/sql/connect/odbc/linux-mac/installing-the-microsoft-odbc-driver-for-sql-server?view=sql-server-2017
curl https://packages.microsoft.com/keys/microsoft.asc | sudo gpg --dearmour -o /etc/apt/trusted.gpg.d/microsoft.gpg
# Download appropriate package for the OS version
OS=$(grep -P '(?<=^ID=)' /etc/os-release | cut -c 4-)
VERSION=$(lsb_release -rs)

sudo touch /etc/apt/sources.list.d/mssql-release.list
sudo chmod 666 /etc/apt/sources.list.d/mssql-release.list
sudo curl https://packages.microsoft.com/config/$OS/$VERSION/prod.list >/etc/apt/sources.list.d/mssql-release.list
sudo chmod 644 /etc/apt/sources.list.d/mssql-release.list

apt-get update
apt-get install -y curl apt-transport-https
for v in $PHP_VERSIONS; do
  apt-get install -y -o Dpkg::Options::="--force-confold" "$v" "$v"-dev "$v"-xml
done
ACCEPT_EULA=Y apt-get install -y msodbcsql18
# optional: for bcp and sqlcmd
ACCEPT_EULA=Y apt-get install -y mssql-tools18
echo 'export PATH="$PATH:/opt/mssql-tools/bin"' >>~/.bash_profile
echo 'export PATH="$PATH:/opt/mssql-tools/bin"' >>~/.bashrc
# optional: for unixODBC development headers
sudo apt-get install -y unixodbc-dev
# optional: kerberos library for debian-slim distributions
# sudo apt-get install -y libgssapi-krb5-2

# https://github.com/microsoft/msphpsql/issues/1438
apt-get install -y --allow-downgrades odbcinst=2.3.7 odbcinst1debian2=2.3.7 unixodbc=2.3.7 unixodbc-dev=2.3.7

# https://learn.microsoft.com/en-us/sql/connect/php/installation-tutorial-linux-mac?view=sql-server-2017#step-3-install-the-php-drivers-for-microsoft-sql-server
# See https://stackoverflow.com/questions/40419718/how-to-install-php-extension-using-pecl-for-specific-php-version-when-several-p/48352487
for v in $PHP_SUFFIXES; do
  pecl -d php_suffix="$v" install sqlsrv
  pecl -d php_suffix="$v" install pdo_sqlsrv
  # This does not remove the extensions; it just removes the metadata that says
  # the extensions are installed.
  pecl uninstall -r sqlsrv
  pecl uninstall -r pdo_sqlsrv
done
for v in $PHP_SUFFIXES; do
  touch /etc/php/"$v"/mods-available/sqlsrv.ini
  touch /etc/php/"$v"/mods-available/pdo_sqlsrv.ini
  chmod 666 /etc/php/"$v"/mods-available/*sqlsrv*.ini
  printf "; priority=20\nextension=sqlsrv.so\n" >/etc/php/"$v"/mods-available/sqlsrv.ini
  printf "; priority=30\nextension=pdo_sqlsrv.so\n" >/etc/php/"$v"/mods-available/pdo_sqlsrv.ini
done
phpenmod sqlsrv pdo_sqlsrv

# Step 4 skipped because Apache is already configured.
# Step 5 skipped because Apache is not started at this point.

# Reduce image size some.
if [ -f "/.dockerenv" ]; then
  rm -rf /var/lib/apt/lists/*
fi
