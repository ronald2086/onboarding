#!/bin/bash
# Author: Hari

#################################################################
##EMS DEBIAN CREATION STARTS
#################################################################
ARCH=$1
SYSTEM_RELEASE=$2
if [ ! -d debian_ems2 ]; then
        echo "Creating debian_ems2 directory!!!!"
        mkdir debian_ems2
else
        echo "deleting the existing debian_ems2 directory!!!!!!"
        rm -rf debian_ems2
        echo "Re-creating debian_ems2 directory!!!!"
        mkdir debian_ems2
fi
chmod -R 755 debs2/ems/*
rsync -a --exclude='.git' debs2/ems/* debian_ems2/
mkdir -p debian_ems2/tmp/ems/etc/dhcp/
cp artifacts/scripts/1404/dhcpd.conf debian_ems2/tmp/ems/etc/dhcp/
cp ems/target/ems.war debian_ems2/tmp/ems/var/lib/tomcat6/webapps/ems.war
cp ems_common/enl_utils/target/enl_utils.jar debian_ems2/tmp/ems/home/enlighted/enl_utils.jar
cp ems/src/main/resources/legacy_schema_migration/upgradeSQL_rk.sql debian_ems2/tmp/ems/home/enlighted/
cp ems/artifacts/sql/migration/From_2.0_To_3.0/sppa.sql debian_ems2/tmp/ems/home/enlighted/
echo "Ensure that empty folders are created so cp will succeed"
# Ensure that empty folders are created so "cp" will succeed
mkdir -p debian_ems2/tmp/ems/var/lib/tomcat6/Enlighted/bacnet/config
#Adding bacnet libraries
cp ../BACNET2/EnlightedBACnet.zip  debian_ems2/tmp/ems/var/lib/tomcat6/Enlighted/bacnet/
mkdir -p debian_ems2/tmp/ems/usr/lib/
if [ "$ARCH" = "a32" ]; then
        cp ../BACNET2/libs/i386/* debian_ems2/tmp/ems/usr/lib/
else
        cp ../BACNET2/libs/amd64/* debian_ems2/tmp/ems/usr/lib/
fi
mkdir -p debian_ems2/tmp/ems/home/enlighted/bacnet/tools/
if [ "$ARCH" = "a32" ]; then
        cp artifacts/scripts/1404/bacnet/tools/x86/* debian_ems2/tmp/ems/home/enlighted/bacnet/tools/
else
        cp artifacts/scripts/1404/bacnet/tools/x64/* debian_ems2/tmp/ems/home/enlighted/bacnet/tools/
fi
chmod g-s -R ./debian_ems2
chmod -R 0755 ./debian_ems2/*
dpkg-deb -b debian_ems2 debian_ems2/enLighted.deb
#################################################################
##EMS DEBIAN CREATION ENDS
#################################################################

#################################################################
##TOMCAT DEBIAN CREATION STARTS
#################################################################
if [ ! -d debian_tomcat9 ]; then
        echo "Creating debian_tomcat9 directory!!!!"
        mkdir debian_tomcat9
else
        echo "deleting the existing debian_tomcat9 directory!!!!!!"
        rm -rf debian_tomcat9
        echo "Re-creating debian_tomcat9 directory!!!!"
        mkdir debian_tomcat9
fi
chmod g-s -R ./debs2/tomcat9/*
chmod -R 755 debs2/tomcat9/*
echo "Copying the debian files to debian_tomcat directory!!!!"
rsync -a --exclude='.git' debs2/tomcat9/* debian_tomcat9/
if [ "$ARCH" = "a32" ]; then
        cp debian_tomcat9/src/apache-tomcat-9.0.33.tar.gz debian_tomcat9/tomcat9_x86/
        dpkg-deb -b debian_tomcat9/tomcat9_x86/ debian_tomcat9/tomcat9_i386.deb
else
        cp debian_tomcat9/src/apache-tomcat-9.0.33.tar.gz debian_tomcat9/tomcat9_x64/
        dpkg-deb -b debian_tomcat9/tomcat9_x64/ debian_tomcat9/tomcat9_amd64.deb
fi
#################################################################
##### TOMCAT DEBIAN CREATION ENDS
#################################################################

#################################################################
##EM MANAGEMENT CREATION STARTS
#################################################################

if [ ! -d debian_mgmt2 ]; then
        echo "Creating debian directory!!!!"
        mkdir debian_mgmt2
else
        echo "deleting the existing debian directory!!!!!!"
        rm -rf debian_mgmt2
        echo "Re-creating debian directory!!!!"
        mkdir debian_mgmt2
fi
chmod -R 755 debs2/em_mgmt_new/*
echo "Copying the debian files to debian_mgmt2 directory!!!!"
rsync -a --exclude='.git' debs2/em_mgmt_new/* debian_mgmt2/
mkdir -p debian_mgmt2/tmp/em_mgmt_new/var/www/em_mgmt/
rsync -a --exclude='.git' em_mgmt/* debian_mgmt2/tmp/em_mgmt_new/var/www/em_mgmt/
cd debian_mgmt2/tmp/em_mgmt_new/var/www/em_mgmt/
chmod -R 766 locale
django-admin.py compilemessages
cd ../../../../../../
# Get revision number from Jenkins BUILD_NUMBER
echo "Revision: $BUILD_NUMBER" >debian_mgmt2/tmp/em_mgmt_new/var/www/em_mgmt/management/templatetags/buildinfo.txt
chmod g-s -R debian_mgmt2
dpkg-deb -b debian_mgmt2 debian_mgmt2/em_mgmt.deb

#################################################################
##EM MANAGEMENT CREATION ENDS
#################################################################

#################################################################
##EM CLOUD COMMUNICATOR CREATION STARTS
#################################################################
if [ -d debian_cloud_communicator2 ]; then
        echo "Recreating debian_cloud_communicator2 directory"
        rm -rf debian_cloud_communicator2
        mkdir debian_cloud_communicator2
else
        echo "Creating debian_cloud_communicator2 directory"
        mkdir debian_cloud_communicator2
fi
chmod -R 755 debs2/cloud_communicator/*
echo "Copying files to debian_cloud_communicator2 directory!!"
rsync -a --exclude='.git' debs2/cloud_communicator/* debian_cloud_communicator2/

echo "Copying em_cloud_communicator.jar to debian_cloud_communicator2/tmp/cloud_communicator/opt/enLighted/communicator directory!!"
cp em_cloud_communicator/target/em_cloud_communicator.jar debian_cloud_communicator2/tmp/cloud_communicator/opt/enLighted/communicator
echo "Creating debian package!!!!!"
chmod g-s -R debian_cloud_communicator2
dpkg-deb -b debian_cloud_communicator2 debian_cloud_communicator2/em_cloud_communicator.deb

#################################################################
##EM CLOUD COMMUNICATOR CREATION ENDS
#################################################################

#################################################################
##SECURITY PATCH UPGRADE DEB CREATION STARTS
#################################################################
#!/bin/bash
packages=./debs2/security_upgrade/packages
target="./debs2/security_upgrade/em_security_upgrade/tmp/em_all/home/enlighted/debs/security"
FILES_FOUND = 0
FILES_DOWNLOADED = 0
if [ -e "$packages" ]; then
	    echo "SECURITY UPGRADE :: PACKAGES FILE FOUND. READING FILES"
	    mkdir -p "security_upgrade_patch"
		while IFS= read -r line; do
			c=( $line )
			echo "===> Found package entry ::  ${c[3]//-/_}"
			FILES_FOUND=$((FILES_FOUND + 1))
			mkdir -p ./security_upgrade_patch/${c[1]//[^[:alnum:]]/}
			# perform curl operation
			CURL_RETURN_CODE=0
			CURL_OUTPUT=`curl --connect-timeout 5 --max-time 100 --retry 5 --retry-delay 0 --retry-max-time 40 -w httpcode=%{http_code} -o ./security_upgrade_patch/${c[1]//[^[:alnum:]]/}/${c[3]//-/_}  ${c[2]} 2> /dev/null` || CURL_RETURN_CODE=$?
			echo "Downloading... ${c[3]//-/_}"
			if [ ${CURL_RETURN_CODE} -ne 0 ]; then
				echo "ERROR - SECURITY UPGRADE :: CURL FAILED - ${CURL_RETURN_CODE}"
			else
				echo "SECURITY UPGRADE :: SUCCESSFULLY DOWNLOADED DEB"
				# Check http code for curl operation/response in  CURL_OUTPUT
				httpCode=$(echo "${CURL_OUTPUT}" | sed -e 's/.*\httpcode=//')
				if [ ${httpCode} -ne 200 ] && [ ${httpCode} -ne 303 ]; then
					echo "ERROR - EMS SECURITY UPGRADE :: CURL OPERATION FAILED - ${httpCode}"
				else
					FILES_DOWNLOADED=$((FILES_DOWNLOADED + 1))
				fi
			fi
		done < $packages
else
	echo "ERROR - SECURITY UPGRADE :: NO PACKAGES FILE FOUND. NOTHING TO UPGRADE"
fi

if [ ${FILES_FOUND} -eq ${FILES_DOWNLOADED} ] && [ ${FILES_DOWNLOADED} -ne 0 ]; then
	echo "SECURITY UPGRADE :: SUCCESSFULLY DOWNLOADED ${FILES_DOWNLOADED} DEBIAN FILES"
	if [ -d "./debs2/security_upgrade" ]; then
		echo "EMS SECURITY UPGRADE DEBIAN CREATION STARTS"
		chmod g-s -R debs2/security_upgrade/em_security_upgrade/DEBIAN/
	  chmod -R 0755 debs2/security_upgrade/em_security_upgrade/DEBIAN/
	  chmod -R 0777 debs2/security_upgrade/em_security_upgrade/tmp/
	  chmod +x ./debs2/security_upgrade/em_security_upgrade/tmp/em_all/home/enlighted/debs/security/security_upgrade_patch/run_security_upgrade.sh
		cp -R ./security_upgrade_patch/ $target
		dpkg-deb -b ./debs2/security_upgrade/em_security_upgrade em_security_upgrade.deb
		if [ $? -eq 0 ]; then
		    mkdir -p "debian_security_patch"
		    chmod g-s -R ./debian_security_patch
            chmod -R 0755 ./debian_security_patch/
		    cp em_security_upgrade.deb debian_security_patch/
			echo "SECURITY UPGRADE DEBIAN CREATION ENDED SUCCESSFULLY"
		else
			echo "ERROR - SECURITY UPGRADE :: FAILED TO CREATE DEB"
		fi
	else
		echo "ERROR - SECURITY UPGRADE :: NOTHING TO ARCHIVE"
	fi
else
	echo "ERROR - SECURITY UPGRADE :: FAILED TO DOWNLOAD ALL DEB FILE"
fi
#################################################################
##SECURITY PATCH UPGRADE DEB CREATION ENDS
#################################################################


#################################################################
##MOVING RESPECTIVE DEBIAN FOR PACKING ALL
#################################################################
mv debian_ems2/enLighted.deb debian_ems2/${BUILD_NUMBER}_enLighted.deb
mv debian_mgmt2/em_mgmt.deb debian_mgmt2/${BUILD_NUMBER}_em_mgmt.deb
mv debian_cloud_communicator2/em_cloud_communicator.deb debian_cloud_communicator2/${BUILD_NUMBER}_em_cloud_communicator.deb
mv debian_security_patch/em_security_upgrade.deb debian_security_patch/${BUILD_NUMBER}_em_security_upgrade.deb
#################################################################
## DEBIAN ALL CREATION STARTS
#################################################################
if [ -d debian_em_all2 ]; then
        echo "Recreating debian_em_all2 directory"
        rm -rf debian_em_all2
        mkdir debian_em_all2
else
        echo "Creating debian_em_all2 directory"
        mkdir debian_em_all2
fi
echo "Copying files to debian_em_all2 directory!!"
rsync -a --exclude='.git' debs2/em_all/* debian_em_all2/

if [ "$ARCH" = "a32" ]; then
        cp debian_em_all2/tmp/em_all/etc/apt/sources.list.32 debian_em_all2/tmp/em_all/etc/apt/sources.list
else
        cp debian_em_all2/tmp/em_all/etc/apt/sources.list.64 debian_em_all2/tmp/em_all/etc/apt/sources.list
fi

echo "CurrentRevision: $BUILD_NUMBER" >>debian_em_all2/DEBIAN/control
echo "ValidationKey: enLighted" >>debian_em_all2/DEBIAN/control
echo "SystemRelease: $SYSTEM_RELEASE" >>debian_em_all2/DEBIAN/control
mkdir -p debian_em_all2/tmp/em_all/home/enlighted/debs/
cp debian_ems2/${BUILD_NUMBER}_enLighted.deb debian_em_all2/tmp/em_all/home/enlighted/debs/
cp debian_mgmt2/${BUILD_NUMBER}_em_mgmt.deb debian_em_all2/tmp/em_all/home/enlighted/debs/
cp debian_cloud_communicator2/${BUILD_NUMBER}_em_cloud_communicator.deb debian_em_all2/tmp/em_all/home/enlighted/debs/
cp debian_security_patch/${BUILD_NUMBER}_em_security_upgrade.deb debian_em_all2/tmp/em_all/home/enlighted/debs/
mkdir -p debian_em_all2/tmp/em_all/var/lib/tomcat6/webapps/ROOT/
cp -R mobile/Deployables/release/emsMobile* debian_em_all2/tmp/em_all/var/lib/tomcat6/webapps/ROOT/
echo "Creating debian package!!!!!"
chmod g-s -R debian_em_all2
dpkg-deb -b debian_em_all2 debian_em_all2/em_all.deb

#################################################################
## DEBIAN ALL CREATION ENDS
#################################################################
mv debian_em_all2/em_all.deb debian_em_all2/${BUILD_NUMBER}_${ARCH}_em_all.deb
cp em_mgmt/adminscripts/debian_upgrade.sh debian_em_all2/${BUILD_NUMBER}_${ARCH}_debian_upgrade.sh
