locals {
  postgres_version             = "12.4"
  postgres_family              = "aurora-postgresql12"
  backup_retention_period      = 1
  preferred_backup_window      = "07:20-07:50"
  preferred_maintenance_window = "sun:10:20-sun:10:50"
  rds_name                     = format("%s-%s-%s-rds", var.service, var.region, var.environment)
  dr_rds_name                  = format("%s-%s-%s-rds", var.service, var.dr_region, var.environment)
  rto_date_time                = data.external.date_time_for_rto_backup.result
  latest_awsbackup_id          = data.external.latest_awsbackup_snapshot.result
  aws_get_snapshot_cmd = format("aws rds describe-db-cluster-snapshots --region %s --filters 'Name=snapshot-type,Values=manual,awsbackup' 'Name=db-cluster-id,Values=%s,%s' --query \"reverse(sort_by(DBClusterSnapshots[?Status=='available'], &SnapshotCreateTime))[?(SnapshotCreateTime>'%s')].{id:DBClusterSnapshotIdentifier,cluster:DBClusterIdentifier,snapshotTime:SnapshotCreateTime,status:Status}[0]\"",
  var.region, local.rds_name, local.dr_rds_name, local.rto_date_time.dateTime)
  manage_database_name     = var.manage_database_name
  database_master_username = "postgres"

}

data "external" "date_time_for_rto_backup" {
  program = ["sh", "${path.module}/script.sh"]
}

data "external" "latest_awsbackup_snapshot" {
  program = ["bash", "-c", local.aws_get_snapshot_cmd]
}

resource "null_resource" "debug_rto_date_time_resource" {
  triggers = local.rto_date_time
  provisioner "local-exec" {
    command = "echo 'date_time_for_rto_backup = local.rto_date_time.dateTime'"
  }
}

module "rds-postgres" {
  source                        = "git::ssh://git@bitbucket.org/enlightedinc/terraform-enl-aws-rds-postgres?ref=v0.8.9"
  service                       = var.service
  region                        = var.region
  environment                   = var.environment
  owner                         = var.owner
  rds_map_server_id             = var.rds_map_server_id
  subnets                       = var.database_subnets
  vpc_id                        = var.vpc_id
  database_name                 = var.manage_database_name
  username                      = local.database_master_username
  allowed_cidr_blocks           = var.allowed_cidr_blocks
  deletion_protection           = "false"
  storage_encrypted             = "true"
  postgres_version              = local.postgres_version
  aurora-postgresql-family-name = local.postgres_family
  instance_type                 = var.db_instance_type
  replica_count                 = var.db_replica_count
  backup_retention_period       = local.backup_retention_period
  preferred_backup_window       = local.preferred_backup_window
  preferred_maintenance_window  = local.preferred_maintenance_window
  snapshot_identifier           = var.tenant_rds_snapshot_identifier != "" ? var.tenant_rds_snapshot_identifier : lookup(local.latest_awsbackup_id, "id", null)
  enable_log_forwarding         = var.enable_log_forwarding
  log_destination_name          = var.log_destination_name
  rds_postgres_timezone         = var.tenant_instance_timezone
  apply_immediately             = "true"
  password                      = random_password.master_password.result

  enabled_cloudwatch_logs_exports = [
    "postgresql"
  ]
}

# Random string to use as master password unless one is specified
resource "random_password" "master_password" {
  length  = 16
  special = false
}
