# Energy Manager on AWS setup.

## Introduction
The deployment of Enlighted Energy Manager on AWS.

## Prerequisite
### AWS SDK cli setup
### AWS Okta login setup:
    Setup gimmecred for aws activity and follow https://enlightedinc.atlassian.net/wiki/spaces/SLM/pages/1253539935/AWS+Authentication+with+Okta
### Terraform 0.12


#  Energy Manager on AWS
## Introduction
The deployment of Enlighted Energy Manager on AWS.

## Setup & Deployment

 1. Install AWS SDK and CLI
 2. Setup gimmecred for aws activity and follow confluence link https://enlightedinc.atlassian.net/wiki/spaces/SLM/pages/1253539935/AWS+Authentication+with+Okta

 3. Deploy Manage on Playground
	 - cd to **gems/manage_infra/live/base/bootstrap**
	 - gimmecred based on AWS role ( cmd execution)
	 - Verify OR Create playground/tenant terraform state S3 bucket. If bucket and dynamo table already exists then no need create again.This is one time setup per tenant/developer .
		  -	 `export TF_VAR_region="us-east-1"`
		  -  `export TF_VAR_tenant_instance_name=<<name_of_the_tenant_instance_workspace>>;`  ex: export TF_VAR_tenant_instance_name=rajus;
		  -  `export AWS_PROFILE=enl-playground-Administrator;`
		  -	 `export ENVIRONMENT="playground"`
		  -	 `export VAR_FILE_NAME="${ENVIRONMENT}.tfvars"`
		 -   `terraform init -input=false`
		 -   `terraform plan -input=false -var-file=./${VAR_FILE_NAME}` (This plan command tells before apply what it is going to create, check more on terraform learning)
		 -   `terraform apply -input=false --auto-approve -var-file=./${VAR_FILE_NAME}`
	 - Deploying Manage Application
		 - cd to **gems/manage_infra/live/base/playground**
		 - Initialize terraform.
         - `export TF_VAR_region="us-east-1"`
		     - `export TF_VAR_tenant_instance_name=<<name_of_the_tenant_instance_workspace>>;`  ex: export TF_VAR_tenant_instance_name=rajus;
		     - `export AWS_PROFILE=enl-playground-Administrator;`
		     - `export ENVIRONMENT="playground"`
			 - `terraform init -input=false -backend-config=../base/backend/playground.tfvars -backend-config="dynamodb_table=${TF_VAR_tenant_instance_name}-manage-lock-${REGION}-${ENVIRONMENT}-dynamodb" -backend-config="bucket=enl-${TF_VAR_tenant_instance_name}-manage-${REGION}-${ENVIRONMENT}-terraform"`

		 - Run terraform apply to deploy Manage Application
			 - `terraform plan -input=false`
			 - `terraform validate` ( To validate terraform source is valid or not)
			 - `terraform apply -input=false --auto-approve`
 4. Deploy on dev environment or via jenkins job changes.

	 - setup bootstrap configuration of terraform state with S3 bucket and dynamo table module
	   - cd to **gems/manage_infra/live/base/bootstrap**
	   - `export TF_VAR_region="us-east-1"`
	   - `export ENVIRONMENT="dev"`
	   - `export VAR_FILE_NAME="${ENVIRONMENT}.tfvars"`
	   - `terraform init -input=false`
	   - `terraform plan -input=false -var-file=./${VAR_FILE_NAME}` (This plan command tells before apply what it is going to create, check more on terraform learning)
	   - `terraform apply -input=false --auto-approve -var-file=./${VAR_FILE_NAME}`
	 - Deploy Manage application
	   - cd to **gems/manage_infra/live/base**
	   -  Initialize terraform before selecting workspace(customer workspace) name.
      	     - `export TF_VAR_region="us-east-1"`
      	     - `export BE_FILE_NAME="${ENVIRONMENT}backend.tfvars"`
			 - `terraform init -input=false -backend-config=./backend/${BE_FILE_NAME}`
	   - Check what is customer current workspace name
			- `terraform workspace show`
			- if it is **default** then select exists workspace OR create new workspace based on customer instance setup.
			- **Note**: It is not recommended to use default workspace.
	  - Create your new customer workspace name if not exists (ex: salesforce2)
      	- `terraform workspace new salesforce2`
      - Select if customer workspace already exists
        - `terraform workspace select saleforce3`
	  - Run terraform apply to deploy Manage Application
    	 - `export ENVIRONMENT="dev"`
    	 - `export TF_VAR_region="us-east-1"`
    	 - `export VAR_FILE_NAME="${ENVIRONMENT}.tfvars"`
    	 - `terraform init -input=false -backend-config=./backend/${BE_FILE_NAME}`
    	 - `terraform validate` ( To validate terraform source is valid or not)
    	 - `terraform plan -input=false -var-file=./tfvars/${VAR_FILE_NAME}`
    	 - `terraform apply -input=false --auto-approve -var-file=./tfvars/${VAR_FILE_NAME}`

Note: Please edit readme based on your findings and new changes.
