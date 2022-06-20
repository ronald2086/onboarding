#!/bin/bash
echo "  ------ Manage deployment bundle preparation --------------"
if [ -z "${WORKSPACE}" ]
then
    echo 'Please provide gems path to WORKSPACE environment variable, ex: $HOME/gems'
    exit 1
else
    echo "preparaing deployment bundle from manage project path ${WORKSPACE}"
    sleep 3
fi
if [ -z "${artifactVersion}" ]
then
    echo 'artifactVersion not found so assigning default value to local'
    export artifactVersion="local"
fi
if [ ! -f "${WORKSPACE}/ems/target/ems.war" ]
then
    echo "Seems to be ems.war file does not exist under path ${WORKSPACE}/ems/target/ems.war, please build ems maven project to generate it then run again."
    exit 1
fi

rm -fr ${WORKSPACE}/nexus_uploadable_artifacts
rm -rf ${WORKSPACE}/nexus_final_zip
mkdir -p ${WORKSPACE}/nexus_uploadable_artifacts
cp -r ${WORKSPACE}/manage_infra ${WORKSPACE}/nexus_uploadable_artifacts/
mkdir -p ${WORKSPACE}/nexus_uploadable_artifacts/manage-beanstalk-zip

echo "  ------ Getting Manage application version from gems/pom.xml --------------"
manageAppVersion=$(mvn -f ${WORKSPACE}/pom.xml help:evaluate -Dexpression=currentVersion -q -DforceStdout)
cd ${WORKSPACE}/nexus_uploadable_artifacts/manage-beanstalk-zip/
echo "  ------ Copying ems.war --------------"
cp -r ${WORKSPACE}/ems/target/ems.war ./
mkdir -p .ebextensions/Enlighted
mkdir -p .ebextensions/Enlighted/ems_log4j
mkdir -p .ebextensions/Enlighted/UpgradeImages
mkdir -p .ebextensions/Enlighted/tmp

cp ${WORKSPACE}/ems/src/Enlighted/adminpasswd .ebextensions/Enlighted/
cp ${WORKSPACE}/debs/em_mgmt_new/bin/authadmin.sh .ebextensions/Enlighted/
cp ${WORKSPACE}/ems/src/Enlighted/ems_log4j/log4j.properties .ebextensions/Enlighted/
cp ${WORKSPACE}/ems/src/Enlighted/ems_log4j/log4j.properties_DEBUG .ebextensions/Enlighted/
cp ${WORKSPACE}/debs2/em_mgmt_new/tmp/em_mgmt_new/home/enlighted/checkandsetemmode.sh .ebextensions/Enlighted/
cp ${WORKSPACE}/debs2/ems/tmp/ems/home/enlighted/emsmode .ebextensions/Enlighted/
cp -r ${WORKSPACE}/ci/jenkins_pipeline/beanstalk_configs/* .ebextensions/Enlighted/
rm -fr .ebextensions/Enlighted/*.config
rm -rf .ebextensions/Enlighted/ROOT.war
rm -rf .ebextensions/Enlighted/httpd
cp ${WORKSPACE}/ci/jenkins_pipeline/beanstalk_configs/manage-app-deplyment.config .ebextensions/
cp ${WORKSPACE}/ci/jenkins_pipeline/beanstalk_configs/manage_logs.config .ebextensions/
cp ${WORKSPACE}/ci/jenkins_pipeline/beanstalk_configs/passphrase.sh .ebextensions/Enlighted/
cp ${WORKSPACE}/ci/jenkins_pipeline/beanstalk_configs/ROOT.war .
cp .ebextensions/Enlighted/log4j.properties_DEBUG .ebextensions/Enlighted/ems_log4j/log4j.properties

mkdir .ebextensions/Enlighted/fixture-info-table
cp ${WORKSPACE}/debs2/ems/tmp/ems/var/lib/tomcat6/Enlighted/fixture-info-table/fmt.xsd .ebextensions/Enlighted/fixture-info-table
cp ${WORKSPACE}/debs2/ems/tmp/ems/home/enlighted/plugload_profile.xsd .ebextensions/Enlighted/
cp ${WORKSPACE}/debs2/ems/tmp/ems/home/enlighted/sensor_profile.xsd .ebextensions/Enlighted/
cp ${WORKSPACE}/ems_common/enl_utils/target/enl_utils.jar .ebextensions/Enlighted/

# prepare manage beanstalk zip
echo "  ------ Manage beanstalk zip preparation --------------"
zip -r "${WORKSPACE}/nexus_uploadable_artifacts/manage-app-bundle-${artifactVersion}-${manageAppVersion}.zip" .
zip -r "${WORKSPACE}/nexus_uploadable_artifacts/manage-app-bundle-${artifactVersion}-${manageAppVersion}.zip" . -x ".DS_Store" -x "__MACOSX"
unamestr=`uname`
if [[ "$unamestr" == 'Darwin' ]]; then
   exit 0
fi 
cd ${WORKSPACE}/nexus_uploadable_artifacts
rm -fr ${WORKSPACE}/nexus_uploadable_artifacts/manage-beanstalk-zip
ls -ltr ${WORKSPACE}/nexus_uploadable_artifacts
mkdir -p ${WORKSPACE}/nexus_final_zip
echo "  ------ Nexus uploadable zip preparation --------------"
zip -r "${WORKSPACE}/nexus_final_zip/manage-app-infra-${artifactVersion}-${manageAppVersion}.zip" . -x ".DS_Store" -x "__MACOSX"
echo "  ------ Manage deployment zip ready for nexus upload --------------"
