region         = "us-east-1"
encrypt        = true
key            = "terraform.tfstate"
dynamodb_table = "__TENANT_INSTANCE_NAME__-manage-lock-us-east-1-__ENVIRONMENT__-dynamodb" //pragma: allowlist secret
bucket         = "enl-__TENANT_INSTANCE_NAME__-manage-us-east-1-__ENVIRONMENT__-terraform" //pragma: allowlist secret