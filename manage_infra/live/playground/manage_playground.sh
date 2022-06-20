#!/bin/bash
echo "--------------- Playground --------------"
export RUN_MODE=$1
if [ -z "${RUN_MODE}" ]
then
    RUN_MODE="apply"
fi

echo "TENANT_INSTANCE_NAME :${TENANT_INSTANCE_NAME}"
echo "CIDR                 :${CIDR}"
echo "PRIVATE_SUBNETS      :${PRIVATE_SUBNETS}"
echo "PUBLIC_SUBNETS       :${PUBLIC_SUBNETS}"
echo "DATABASE_SUBNETS     :${DATABASE_SUBNETS}"
echo "AWS_REGION           :${AWS_REGION}"
echo "ENVIRONMENT          :${ENVIRONMENT}"
echo "AWS_PROFILE          :${AWS_PROFILE}"


if [[ -z "${TENANT_INSTANCE_NAME}" || -z "${CIDR}" || -z "${PRIVATE_SUBNETS}" || -z "${PUBLIC_SUBNETS}" || -z "${DATABASE_SUBNETS}" || -z "${AWS_REGION}" || -z "${ENVIRONMENT}" ]]
then
    echo 'Please export TENANT_INSTANCE_NAME, CIDR, PRIVATE_SUBNETS, PUBLIC_SUBNETS, DATABASE_SUBNETS, AWS_REGION'
    exit 1
fi

export TF_VAR_tenant_instance_name="${TENANT_INSTANCE_NAME}"
export TF_VAR_cidr="${CIDR}"
export TF_VAR_private_subnets="${PRIVATE_SUBNETS}"
export TF_VAR_public_subnets="${PUBLIC_SUBNETS}"
export TF_VAR_database_subnets="${DATABASE_SUBNETS}"
export TF_VAR_region="${AWS_REGION}"


BACKEND_FILE=$HOME/${TENANT_INSTANCE_NAME}-backend.tfvars
cp ../base/backend/terraform-state-backend.tfvars $BACKEND_FILE
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

echo "\n---------------TERRAFORM INIALIZATION ($TF_VAR_tenant_instance_name) ------------------"
terraform init -input=false -backend-config=$BACKEND_FILE
status=$?
## take some decision ##
if [ $status -eq 0 ]
then
    echo "terraform initialization successfully executed..."
else
    echo "please check error cause then rerun again init"
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
    terraform apply -input=false --auto-approve
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
    terraform destroy -input=false -auto-approve
    status=$?
    if [ $status -eq 0 ]
    then
        echo "terraform ${RUN_MODE} passed"
    else
        echo "please check terraform destroy errors cause then rerun again"
        exit 1
    fi
fi
