#!/bin/bash

# Title Function
func_title(){
  # Clear (For Prettyness)
  clear
  # Title
  echo '============================================================================'
  echo ' Geotables.sh | [Version]: 1.0 | [Updated]: 11.13.2013'
  echo '============================================================================'
  echo
}

# Install Xtables-Addons Function
func_install(){
  # Print Title
  func_title
  # Debian-Based Installer
  if [ -f /etc/debian_version ]
  then
    echo '[*] Identified OS: Debian-Based'
    echo '[*] Installing Dependencies Using: apt-get'
    echo '[*] Updating Package Lists'
    apt-get -qq update
    echo '[*] Obtaining Required Packages'
    apt-get -q install xtables-addons-dkms wget gzip unzip libtext-csv-perl
    echo '[*] Apt Cleaning'
    apt-get -qq clean && apt-get -qq autoclean
    echo '[*] Initializing First Run Update'
    func_update
  # RHEL-Based Installer
  elif [ -f /etc/system-release ]
    then
    kerneldev=`uname -r`
    failed=0
    # RHEL-Based Installer Based On Web Article By TiTex
    # (http://www.howtoforge.com/xtables-addons-on-centos-6-and-iptables-geoip-filtering)
    echo '[*] Identified OS: RHEL-Based'
    echo '[*] WARNING: Continuing Will...'
    echo ' |---> Disable SELinux'
    echo ' |---> Add RPMForge Yum Repository'
    read -p '[?] Continue With Install? (y/n): ' install
    if [ ${install} == 'y' ]
    then
      echo '[*] Disabling SELinux'
      sed -i 's/SELINUX=.*/SELINUX=disabled/g' /etc/selinux/config
      echo 0 > /selinux/enforce
      echo '[*] Adding RPMForge Yum Repository'
      rpm -i http://packages.sw.be/rpmforge-release/rpmforge-release-0.5.2-2.el6.rf.i686.rpm
      echo '[*] Installing Dependencies Using: yum+gcc'
      yum install gcc gcc-c++ make automake unzip zip xz kernel-devel-${kerneldev} iptables-devel wget perl-Text-CSV_XS
      echo '[*] Verifying Dependency Installation'
      for pkg in gcc gcc-c++ make automake unzip zip xz kernel-devel-${kerneldev} iptables-devel wget perl-Text-CSV_XS
      do
        installed=`rpm -qa|grep '^${pkg}'|wc -l`
        if [ ${installed} == '0' ]
        then
          echo "[!] ${pkg} Failed Installation"
          ((failed++))
        fi
      done
      if [ ${failed} != '0' ]
      then
        echo '[!] Installation Aborted.'
        echo '[!] Reason: Failed Dependency Installation'
        echo
        exit 1
      fi
      echo '[*] Dependencies Installed Successfully'
      echo '[*] Downloading xtables-addons Source' 
      wget -q http://downloads.sourceforge.net/project/xtables-addons/Xtables-addons/1.37/xtables-addons-1.37.tar.xz
      tar -xf xtables-addons-1.37.tar.xz && cd xtables-addons-1.37/
      echo '[*] Building xtables-addons'
      ./configure && make
      echo '[*] Installing xtables-addons'
      make install
      echo '[*] Initializing First Run Update'
      cd ..
      func_update
    else
      echo '[*] Installation Aborted.'
      echo
    fi
  # Abort Message For Unknown/Unsupported OS
  else
    echo '[!] Could Not Detect Operating System'
    echo '[!] Manual Installation of Xtables-Addons is Required.'
    echo
    exit 1
  fi
}

# Update GeoIP Data Files Function
func_update(){
  # Check For Necessary Directories
  if [  ! -d /usr/share/xt_geoip ]
  then
    echo '[*] Creating Directory: /usr/share/xt_geoip'
    mkdir /usr/share/xt_geoip
  fi
  echo '[*] Changing Directories'
  cd `dirname ${0}`
  # Download And Decompression Based On xt_geoip_dl
  echo '[*] Downloading MaxMind Databases'
  wget -q http://geolite.maxmind.com/download/geoip/database/GeoIPv6.csv.gz
  wget -q http://geolite.maxmind.com/download/geoip/database/GeoIPCountryCSV.zip
  echo '[*] Decompressing Archives'
  gzip -qd GeoIPv6.csv.gz
  unzip -q GeoIPCountryCSV.zip
  echo '[*] Building GeoIP Data Files'
  # xt_geoip_build Created And Copyrighted By Jan Engelhardt.
  ./xt_geoip_build -D /usr/share/xt_geoip *.csv|awk '!/ranges for/'
  echo '[*] Cleaning Up'
  rm -rf *.zip *.gz *.csv BE LE xtables-addons-*
  echo '[*] Finished'
  echo
}

# Privileges Check
if [ `whoami` != root ]
then
  func_title
  echo '[!] This script requires root privileges.'
  echo
  exit 1
fi

# Start Statement
case $1 in
  -i)
    func_install
    ;;
  -u)
    func_update
    ;;
  *)
    func_title
    echo "[Usage]...: ${0} [OPTION]"
    echo
    echo '[Options].:'
    echo '            -i = Install Xtables-Addons'
    echo '            -u = Update GeoIP Data Files'
    echo '            -h = Show This Help Menu'
    echo
    ;;
esac
