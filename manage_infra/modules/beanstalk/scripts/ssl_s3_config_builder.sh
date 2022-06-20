manage_aws_region_name=$1
manage_artifacts_s3_bucket_name=$2
manage_instance_ec2_role_name=$3
manage_app_zip_bundle=$4
ssl_cert_key_s3_config_file_path=$5
ssl_443_listener_config_file_path=$6
manage_tenant_name=$7
echo "---------preparting ssl config file----------------------------------------"
echo "manage_aws_region_name            : $manage_aws_region_name"
echo "manage_artifacts_s3_bucket_name   : $manage_artifacts_s3_bucket_name"
echo "manage_app_zip_bundle             : $manage_app_zip_bundle"
echo "manage_instance_ec2_role_name     : $manage_instance_ec2_role_name"
echo "ssl_cert_key_s3_config_file_path  : $ssl_cert_key_s3_config_file_path"
echo "ssl_443_listener_config_file_path : $ssl_443_listener_config_file_path"
echo "tenant name                       : $manage_tenant_name"
echo "script current path               : `pwd`"

#------- copy template file current working directory --------------
mkdir -p .ebextensions
ssl_cert_key_s3_config_file="./.ebextensions/ssl-cert-key-from-s3.config"
cp -r $ssl_cert_key_s3_config_file_path $ssl_cert_key_s3_config_file

unamestr=`uname`
if [[ "$unamestr" == 'Darwin' ]]; then
   sed -i "" "s/__manage_s3_bucket_name__/$manage_artifacts_s3_bucket_name/g" $ssl_cert_key_s3_config_file
   sed -i "" "s/__manage_s3_access_ec2_role_name__/$manage_instance_ec2_role_name/g" $ssl_cert_key_s3_config_file
else
   sed -i "s/__manage_s3_bucket_name__/$manage_artifacts_s3_bucket_name/g" $ssl_cert_key_s3_config_file
   sed -i "s/__manage_s3_access_ec2_role_name__/$manage_instance_ec2_role_name/g" $ssl_cert_key_s3_config_file
fi

echo "---------content of ssl certs config file : $ssl_cert_key_s3_config_file------------"
cat $ssl_cert_key_s3_config_file
echo "-----------------------------------------------------------------------"

# replace manage dns name under ssl s3 config file
mkdir -p ./.ebextensions/httpd/conf.d/
apache_ssl_443_listener_file="./.ebextensions/httpd/conf.d/ssl_443_listener.conf"
cp -r $ssl_443_listener_config_file_path $apache_ssl_443_listener_file
if [[ "$unamestr" == 'Darwin' ]]; then
   sed -i "" "s/__manage_dns_server_name__/$manage_tenant_name.com/g" $apache_ssl_443_listener_file
else
   sed -i "s/__manage_dns_server_name__/$manage_tenant_name.com/g" $apache_ssl_443_listener_file
fi

echo "---------ssl 443 config file : $apache_ssl_443_listener_file------------"
cat $apache_ssl_443_listener_file
echo "-----------------------------------------------------------------------"

# add ssl-cert-key-from-s3.config into application zip file
zip  -ur $manage_app_zip_bundle $ssl_cert_key_s3_config_file
zip  -ur $manage_app_zip_bundle $apache_ssl_443_listener_file
zip -d $manage_app_zip_bundle "__MACOSX/*"
zip -d $manage_app_zip_bundle "*/.DS_Store"
echo "--------showing zip files----------------------------------------------"
zipinfo $manage_app_zip_bundle