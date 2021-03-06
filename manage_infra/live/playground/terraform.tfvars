region                       = "us-east-1"
environment                  = "playground"
dr_region                    = "us-west-2"
db_instance_type             = "db.t3.medium"
db_replica_count             = 1
log_destination_name         = "enl-playground"
vpn_cidr                     = "10.110.0.0/19"
fargate_cidr                 = "10.66.0.0/16"
default_map_server_id        = "d-server-01qxolivql1b7s"
rds_map_server_id            = "d-server-026pra2xlq3qtv"
environment_stack_name       = "64bit Amazon Linux 2018.03 v3.4.16 running Tomcat 8.5 Java 8"
tomcat_jvm_parameters        = "Xmx=3g,JVM Options=,Xms=512m"
instance_type                = "t2.medium"
application_port             = "443"
ebs_root_volume_size_in_gb   = "50"
manage_database_name         = "ems"
manage_database_username     = "postgres"
enl_master_waf_identifier    = "1615842224534"
enable_alert_alarms          = "true"
iot_core_endpoint            = "auwrgx6d4vss2-ats.iot.us-east-1.amazonaws.com"
tenant_instance_timezone     = "US/Pacific"
enable_port_80_http_redirect = false
