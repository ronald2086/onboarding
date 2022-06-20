#!/bin/bash

#Sanity checking Home & Password
die(){
    echo "FATAL: $*" 1>&2
    exit 1
}

#Start of the execution.
if [ ! -z "$1" ]
then
  iso_directory="$1"
fi

#Defaults
ubuntu_ver="18.04.4"
ubuntu_iso="manage-app-base-iso-1.0.0.iso"
CURR_DIR=`pwd`
EM_DEB=debian_em_all2
DEB_SH=em_mgmt/adminscripts

#Create a folder for custom ISO
mkdir -p newiso
#Create a folder to extract the downloaded ISO
mkdir -p iso

cd $CURR_DIR
#Clean the iso directory
if [ -d "ISO_Build_Dir" ];
then
	rm -rf ISO_Build_Dir/*
else
	mkdir ISO_Build_Dir
fi

#ISO should be available in the home directory before executing below commands
if [[ ! -f $(find 'base-iso' -name 'manage-app-base-iso-1.0.0.iso') ]]
then
  echo "Required base ISO does not exist, please check build pipeline step"
exit 1
fi

#Install required libraries
apt-get update
apt-get update -y
apt-get install -y cmake
apt-get install -y mkisofs

#Unpacking the downloaded ISO and copying into the custom ISO.
cd iso
cmake -E tar xf ../"$iso_directory"/"$ubuntu_iso"
cd ..
cp -r iso/* newiso/
cp -r iso/.disk/ newiso/

mkdir -p newiso/pool/extras
#Clean the pre existing files
rm -rf newiso/preseed/ubuntu-late_command.sh
rm -rf newiso/preseed/packageupgrade.sh
rm -rf newiso/preseed/ubuntu-upgradeoption.seed
rm -rf newiso/preseed/firstrun.sh
rm -rf newiso/preseed/restore.sh
#Start moving the packages
echo Copying preseed files
cp -r ci/preseed/ubuntu-late_command.sh newiso/preseed/ubuntu-late_command.sh
cp -r ci/preseed/packageupgrade.sh newiso/preseed/packageupgrade.sh
cp -r ci/preseed/ubuntu-upgradeoption.seed newiso/preseed/ubuntu-upgradeoption.seed
cp -r ci/preseed/firstrun.sh newiso/preseed/firstrun.sh
cp -r ci/preseed/restore.sh newiso/preseed/restore.sh
#Applications Debs Copying
echo Copying em_all.deb and debian_upgrade.sh to /newiso/preseed/
rm -f newiso/preseed/em_all.deb
rm -f newiso/preseed/debian_upgrade.sh
cp -f $EM_DEB/*em_all.deb newiso/preseed/em_all.deb
cp -f $DEB_SH/debian_upgrade.sh newiso/preseed/debian_upgrade.sh
cp -f ci/install/postgresql-client-9.4_9.4.26-0+deb8u1_amd64.deb newiso/preseed/postgresql-client-9.4_9.4.26-0+deb8u1_amd64.deb

#ISO packaging
echo Building the ISO.
mkisofs -J -l -b isolinux/isolinux.bin -no-emul-boot -boot-load-size 4 -boot-info-table -z -iso-level 4 -c isolinux/isolinux.cat -o ./Enlighted_EM_Server_${ubuntu_ver}_Upgrade_64Bit.iso -joliet-long newiso/

dt="$((`date '+%Y%m%d%H%M%S'`))"
#Moving to Build Directory
mv Enlighted_EM_Server_${ubuntu_ver}_Upgrade_64Bit.iso ISO_Build_Dir/ENL_release_${ubuntu_ver}_64Bit_${dt}.iso

# clean up
rm -rf iso
rm -rf newiso