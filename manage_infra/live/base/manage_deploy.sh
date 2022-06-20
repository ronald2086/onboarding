#!/bin/bash
export RUN_MODE=$1
if [ -z "${RUN_MODE}" ]
then
    RUN_MODE="apply"
fi
echo "Running from path : `pwd`"

echo "TENANT_INSTANCE_NAME :${TENANT_INSTANCE_NAME}"
echo "AWS_REGION           :${AWS_REGION}"
echo "ENVIRONMENT          :${ENVIRONMENT}"


if [ -z "${TENANT_INSTANCE_NAME}" ]
then
    echo 'Please export your own TENANT_INSTANCE_NAME environment variable; ex: export TENANT_INSTANCE_NAME=rajus'
    exit 1
fi
export TF_VAR_tenant_instance_name="${TENANT_INSTANCE_NAME}"
if [ -z "${AWS_REGION}" ]
then
    echo 'Please export AWS_REGION environment variable; ex: export AWS_REGION=us-east-1'
    exit 1
fi

if [ -z "${ENVIRONMENT}" ]
then
    echo 'Please export ENVIRONMENT environment variable; ex: export ENVIRONMENT=playground'
    exit 1
fi
echo "Running tenant name : $TF_VAR_tenant_instance_name, ENVIRONMENT : $ENVIRONMENT, AWS_REGION : $AWS_REGION, RUN_MODE : $RUN_MODE"
if [ -d "$HOME/sw_dsp_manage_tenant_config" ]; then
    echo "Manage tenant config repository already exist under $HOME/sw_dsp_manage_tenant_config"
 else
    git clone git@bitbucket.org:enlightedinc/sw_dsp_manage_tenant_config.git $HOME/sw_dsp_manage_tenant_config
fi
GIT_DIR=$HOME/sw_dsp_manage_tenant_config/.git git checkout master
GIT_DIR=$HOME/sw_dsp_manage_tenant_config/.git git pull

echo "Checking your manage config file available or not"

if [ -f "$HOME/sw_dsp_manage_tenant_config/$ENVIRONMENT/$TENANT_INSTANCE_NAME-terraform.json" ]
then
    echo "file($HOME/sw_dsp_manage_tenant_config/$ENVIRONMENT/$TENANT_INSTANCE_NAME-terraform.json) exist"
else
    echo "TENANT_INSTANCE_NAME($TENANT_INSTANCE_NAME) specific config file($HOME/sw_dsp_manage_tenant_config/$ENVIRONMENT/$TENANT_INSTANCE_NAME-terraform.json) not exist"
    echo "Please create your config file then retry"
    exit 1
fi

echo "Merging common and tenant specific configuration"
TERRAFORM_VAR_FILE=$HOME/$TENANT_INSTANCE_NAME-terraform.tfvars.json
jq -s add $HOME/sw_dsp_manage_tenant_config/$ENVIRONMENT/common-terraform.json $HOME/sw_dsp_manage_tenant_config/$ENVIRONMENT/$TENANT_INSTANCE_NAME-terraform.json > $TERRAFORM_VAR_FILE
echo "Initializing terraform modules"

BACKEND_FILE=$HOME/$TENANT_INSTANCE_NAME-backend.tfvars
cp ./backend/terraform-state-backend.tfvars $BACKEND_FILE
unamestr=`uname`
echo "working o/s name $unamestr"
if [[ "$unamestr" == 'Linux' ]]; then
   sed -i "s/__TENANT_INSTANCE_NAME__/$TENANT_INSTANCE_NAME/g" $BACKEND_FILE
   sed -i "s/__ENVIRONMENT__/${ENVIRONMENT}/g" $BACKEND_FILE
elif [[ "$unamestr" == 'Darwin' ]]; then
   sed -i "" "s/__TENANT_INSTANCE_NAME__/$TENANT_INSTANCE_NAME/g" $BACKEND_FILE
   sed -i "" "s/__ENVIRONMENT__/${ENVIRONMENT}/g" $BACKEND_FILE
fi

echo "---------------showing backend($BACKEND_FILE) file content----------"
cat $BACKEND_FILE

echo "\n---------------showing terraform vars content-------"
cat $TERRAFORM_VAR_FILE
echo "---------------TERRAFORM INIALIZATION ($TF_VAR_tenant_instance_name) ------------------"
terraform init -input=false -backend-config=$BACKEND_FILE
status=$?
## take some decision ##
if [ $status -eq 0 ]
then
    echo "terraform initialization successfully executed..."
else
    echo "please check error cause then rerun again"
    exit 1
fi
echo "---------------TERRAFORM VALIDATION ($TF_VAR_tenant_instance_name)------------------"
terraform validate
status=$?
if [ $status -eq 0 ]
then
    echo "terraform validation passed"
else
    echo "please check validation errors cause then rerun again"
    exit 1
fi

if [ "${RUN_MODE}" == "apply" ]
then
    echo "---------------TERRAFORM APPLY ($TF_VAR_tenant_instance_name)-----------------------"
    terraform apply -input=false --auto-approve -var-file=$TERRAFORM_VAR_FILE
    status=$?
    if [ $status -eq 0 ]
    then
        echo "terraform ${RUN_MODE} passed"
    else
        echo "please check terraform apply errors cause then rerun again"
        exit 1
    fi
fi


if [ "${RUN_MODE}" == "destroy" ]
then
    echo "---------------TERRAFORM DESTROY ($TF_VAR_tenant_instance_name)-----------------------"
    terraform destroy -input=false -auto-approve -var-file=$TERRAFORM_VAR_FILE
    status=$?
    if [ $status -eq 0 ]
    then
        echo "terraform ${RUN_MODE} passed"
    else
        echo "please check terraform destroy errors cause then rerun again"
        exit 1
    fi
fi
