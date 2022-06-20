#!/bin/bash
#Upgarde Packages.
echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections

sudo dpkg -i /opt/enLighted/tmp/postgresql-client-9.4_9.4.26-0+deb8u1_amd64.deb
echo 'installed postgresql 9.4 client util'

sudo mkdir -p /lib/modules
sudo cp -r /upgrade/lib/* /lib/modules/

sudo apt-get -y --purge remove postgresql-10 postgresql-client-10
echo 'Finished package upgrade'