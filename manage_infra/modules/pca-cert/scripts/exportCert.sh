echo "Assume IAM role - ManageCertDeployer"

CREDS_FILE=credentials.json
ACM_CERT=acm_pca_cert.text
aws sts assume-role --role-arn $1 --role-session-name AWSCLI-Session > $CREDS_FILE
export AWS_ACCESS_KEY_ID=$(cat $CREDS_FILE | jq -r '.Credentials.AccessKeyId')
export AWS_SECRET_ACCESS_KEY=$(cat $CREDS_FILE | jq -r '.Credentials.SecretAccessKey')
export AWS_SESSION_TOKEN=$(cat $CREDS_FILE | jq -r '.Credentials.SessionToken')
aws sts get-caller-identity

aws acm export-certificate --region $2 --certificate-arn $3 --passphrase fileb://$4 > ${ACM_CERT}

echo "Parsing ACM CERT response and writing certificate (.pem) and private key (.key) to local files"
cat ${ACM_CERT} | jq -r '.PrivateKey' > $5
cat ${ACM_CERT} | jq -r '.Certificate' > $6

ls -ltr $5 $6

echo "Unset AWS credentials"
unset AWS_ACCESS_KEY_ID
unset AWS_SECRET_ACCESS_KEY
unset AWS_SESSION_TOKEN
