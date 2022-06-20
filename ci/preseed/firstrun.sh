# !/bin/bash

# Adding EM host openssh key file
cp /opt/enLighted/tmp/1004_ssh_host_* /etc/ssh/
sudo chmod 600 /etc/ssh/1004_ssh_host_dsa_key
sudo chmod 600 /etc/ssh/1004_ssh_host_rsa_key
cp /opt/enLighted/tmp/sshd_config /etc/ssh/

# ISC DHCP server and networking settings
#cp /opt/enLighted/tmp/isc-dhcp-server /etc/init.d/isc-dhcp-server
cp /opt/enLighted/tmp/interfaces /etc/network/interfaces

cp /opt/enLighted/tmp/tomcat.conf /etc/init/
# set the PGPORT and PGPASSWORD environment variables in bashrc
echo "export PGPORT=5433" >> /etc/bash.bashrc
echo "export PGPORT=5433" >> /etc/profile
echo "export PGPASSWORD=postgres" >> /etc/bash.bashrc
echo "export PGPASSWORD=postgres" >> /etc/profile
echo "JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64" >> /etc/profile
echo "export PGPORT=5433" >> /etc/apache2/envvars
# add enetry in to resolv.conf for ping gems.enlightedcustomer.net
echo "nameserver 127.0.0.1" >> /etc/resolvconf/resolv.conf.d/head
#Bind Configuration files
sudo rm -rf /etc/bind/
sudo rm -rf /var/lib/bind/
sudo tar xvf /opt/enLighted/tmp/etc-bind.bk.tar -C /
sudo tar xvf /opt/enLighted/tmp/var-bind.bk.tar -C /
sudo cp /opt/enLighted/tmp/named.conf.options /etc/bind/
chmod u+s `which ping`
echo "/usr/bin/dhcpscript ux," >> /etc/apparmor.d/usr.sbin.dhcpd
# copy the pg_hba.conf file to postgres config folder
cp /opt/enLighted/tmp/pg_hba.conf /etc/postgresql/12/main/pg_hba.conf
# set the postgres user password
#sudo -u postgres psql postgres < /opt/enLighted/tmp/psqlpassword.sql
# create the ssl folder in apache and copy the key and pem files
mkdir -p /etc/apache2/ssl
mkdir -p /home/enlighted/django_cache
cp /opt/enLighted/tmp/apache* /etc/apache2/ssl/.
cp /opt/enLighted/tmp/rewrite_prg.pl /etc/apache2/.
cp /opt/enLighted/tmp/000-default.conf /etc/apache2/sites-available/.
if [ `echo $?` -eq 0 ]
then
	echo "Successfully copied" >/home/enlighted/a.log
fi
sudo cp /home/enlighted/.pgpass /var/www/.
sudo chown www-data:www-data /var/www/.pgpass
sudo rm /bin/sh
sudo ln -s /bin/bash /bin/sh
sudo dpkg -i /opt/enLighted/tmp/tomcat9.deb
sudo ln -s /sbin/ifconfig /usr/bin/ifconfig
echo "tomcat ALL=NOPASSWD: /usr/bin/ifconfig" >> /etc/sudoers
sudo chown -R tomcat:tomcat /opt/tomcat/
sudo chown -R tomcat:tomcat /opt/tomcat/
sudo sh /opt/enLighted/tmp/setAllEMEnvironment.sh
if [ -z /backup/etc/hostname ]
then
sudo sh /opt/enLighted/tmp/hostname.sh
fi
sudo mv /opt/enLighted/tmp/restore.sh /restore.sh
# USB mounting
sudo sed -i 's/MOUNTOPTIONS="/MOUNTOPTIONS="user,umask=000,/' /etc/usbmount/usbmount.conf

# Services etc
sudo service postgresql restart

sudo sed -i 's+trusty+bionic+g' /etc/apt/sources.list
sudo update-grub
sudo sh /restore.sh /upgrade/postgres/db.out > /var/log/restore.log 2>&1
sudo sh /opt/enLighted/tmp/debian_upgrade.sh /opt/enLighted/tmp/em_all.deb
sudo cp /upgrade/network/interfaces /etc/network/interfaces
sudo cp /upgrade/network/iptables.rules /etc/iptables.rules
sudo cp /upgrade/etc/timezone /etc/timezone
sudo cp /upgrade/default/isc-dhcp-server /etc/default/isc-dhcp-server
sudo cp /upgrade/etc/ntp.conf /etc/ntp.conf
sudo tar -xvf /upgrade/tomcatEnlighted/tomcatEnlighted.tar.gz -C /
sudo chown -R tomcat:tomcat /opt/tomcat/Enlighted/
sudo chmod -R 775 /opt/tomcat/Enlighted
sudo chmod -R 777 /opt/tomcat/Enlighted/bacnet
sudo chmod -R 777 /opt/tomcat/Enlighted/emsmode
sudo rm -r /tmp/Enlighted/*
sudo rm /opt/tomcat/tomcatEnlighted.tar.gz
sudo cp /upgrade/apache2/apache2.tar.gz /apache2.tar.gz
sudo tar -xvf /apache2.tar.gz -C /
sudo cp /upgrade/etc/hostname /etc/hostname
sudo cp /upgrade/etc/hosts /etc/hosts
export tz=`cat /etc/timezone`
sudo rm -rf /etc/localtime
sudo ln -s /usr/share/zoneinfo/$tz /etc/localtime
sudo cp /upgrade/dhcp/* /var/lib/dhcp/
sudo rm /*.tar.gz
sudo rm -r -f /install
#mv "$0" "$0.bak"
#shutdown -r now

