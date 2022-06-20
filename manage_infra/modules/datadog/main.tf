locals {
  dashboard_title       = "${var.service}-${var.region}-${var.environment}"
  dashboard_layout_type = "ordered"
}

provider "datadog" {
  api_key  = var.datadog_api_key
  app_key  = var.datadog_app_key
  validate = var.enable_dd_dashboard
}


resource "datadog_dashboard" "manage-application-dashboard" {
  count        = var.enable_dd_dashboard ? 1 : 0
  title        = local.dashboard_title
  description  = "Manage application dashboard"
  layout_type  = local.dashboard_layout_type
  is_read_only = false


  widget {

    group_definition {
      layout_type = "ordered"
      title       = "App Load Balancer"
      widget {
        timeseries_definition {
          title       = "requests(all, 4xx, 5xx)"
          show_legend = true
          live_span   = "10m"
          request {
            q            = "sum:aws.applicationelb.request_count{name:${var.beanstalk_environment_name}}.as_count(), sum:aws.applicationelb.httpcode_elb_4xx{name:${var.beanstalk_environment_name}}.as_count(), sum:aws.applicationelb.httpcode_elb_5xx{name:${var.beanstalk_environment_name}}.as_count()"
            display_type = "area"
            style {
              palette    = "cool"
              line_type  = "solid"
              line_width = "thin"
            }
            metadata {
              expression = "sum:aws.applicationelb.request_count{name:${var.beanstalk_environment_name}}.as_count()"
              alias_name = "all"
            }
            metadata {
              expression = "sum:aws.applicationelb.httpcode_elb_4xx{name:${var.beanstalk_environment_name}}.as_count()"
              alias_name = "4xx"
            }
            metadata {
              expression = "sum:aws.applicationelb.httpcode_elb_5xx{name:${var.beanstalk_environment_name}}.as_count()"
              alias_name = "5xx"
            }
          }
        }
      }
      widget {
        query_value_definition {
          autoscale   = true
          custom_unit = "count"
          text_align  = "right"
          precision   = "2"
          title       = "healthy hosts"
          live_span   = "10m"
          request {
            q          = "aws.applicationelb.healthy_host_count{name:${var.beanstalk_environment_name}}"
            aggregator = "last"
            conditional_formats {
              comparator = ">"
              value      = "0"
              palette    = "green_on_white"

            }
            conditional_formats {
              comparator = "<="
              value      = "0"
              palette    = "white_on_red"
            }
          }
        }
      }
      widget {
        timeseries_definition {
          title       = "requests to backend"
          show_legend = true
          live_span   = "10m"
          request {
            q            = "sum:aws.applicationelb.request_count_per_target{name:${var.beanstalk_environment_name}}.as_count()"
            display_type = "area"
            style {
              palette    = "cool"
              line_type  = "solid"
              line_width = "thin"
            }
            metadata {
              expression = "sum:aws.applicationelb.request_count_per_target{name:${var.beanstalk_environment_name}}.as_count()"
              alias_name = "all"
            }
          }
        }
      }


    }
  } // group-1

  widget {
    group_definition {
      layout_type      = "ordered"
      title            = "EC2 Instance"
      background_color = "orange"

      widget {
        timeseries_definition {
          title       = "cpu utilization"
          show_legend = true
          legend_size = "2"
          live_span   = "10m"
          request {
            q            = "avg:aws.ec2.cpuutilization{name:${var.beanstalk_environment_name}}"
            display_type = "area"
            style {
              palette    = "classic"
              line_type  = "solid"
              line_width = "thin"
            }
            metadata {
              expression = "avg:aws.ec2.cpuutilization{name:${var.beanstalk_environment_name}}"
              alias_name = "cpu %"
            }
          }
        }
      } // w-1

      widget {
        query_value_definition {
          request {
            q = "avg:aws.elasticbeanstalk.root_filesystem_util{name:${var.beanstalk_environment_name}}"
            conditional_formats {
              comparator = "<"
              value      = "80"
              palette    = "green_on_white"
            }
            conditional_formats {
              comparator = ">"
              value      = "80"
              palette    = "white_on_red"
            }
          }
          autoscale   = true
          custom_unit = "%"
          text_align  = "right"
          precision   = "2"
          title       = "disk space( > 80% red)"
          live_span   = "10m"
        }
      } // w-2

    }
  } // // group-ec2-3

  widget {
    group_definition {
      layout_type = "ordered"
      title       = "Beanstalk"

      widget {
        timeseries_definition {
          title       = "application request stats(5xx, 4xx and all)"
          show_legend = true
          legend_size = "2"
          live_span   = "10m"
          request {
            q            = "sum:aws.elasticbeanstalk.application_requests_total{name:${var.beanstalk_environment_name}}.as_count(), sum:aws.elasticbeanstalk.application_requests_4xx{name:${var.beanstalk_environment_name}}.as_count(), sum:aws.elasticbeanstalk.application_requests_5xx{name:${var.beanstalk_environment_name}}.as_count()"
            display_type = "area"
            style {
              palette    = "cool"
              line_type  = "solid"
              line_width = "thin"
            }
            metadata {
              expression = "sum:aws.elasticbeanstalk.application_requests_total{name:${var.beanstalk_environment_name}}.as_count()"
              alias_name = "all"
            }
            metadata {
              expression = "sum:aws.elasticbeanstalk.application_requests_4xx{name:${var.beanstalk_environment_name}}.as_count()"
              alias_name = "4xx"
            }
            metadata {
              expression = "sum:aws.elasticbeanstalk.application_requests_5xx{name:${var.beanstalk_environment_name}}.as_count()"
              alias_name = "5xx"
            }
          }


        }
      } // w-2

      widget {
        query_value_definition {
          request {
            q          = "avg:aws.elasticbeanstalk.environment_health{name:${var.beanstalk_environment_name}}"
            aggregator = "last"
            conditional_formats {
              comparator = "<="
              value      = "0"
              palette    = "green_on_white"
            }
            conditional_formats {
              comparator = "<"
              value      = "20"
              palette    = "black_on_light_yellow"
            }
            conditional_formats {
              comparator = ">"
              value      = "20"
              palette    = "white_on_red"
            }
          }
          autoscale  = true
          text_align = "right"
          precision  = "2"
          title      = "environment status(red >= 20, yellow < 20, green = 0)"
          live_span  = "10m"
        }
      } //w-1

    }
  } // group-beanstalk-3


  widget {
    group_definition {
      layout_type = "ordered"
      title       = "RDS"

      widget {
        timeseries_definition {
          title       = "rds connections"
          show_legend = true
          legend_size = "2"
          live_span   = "10m"
          request {
            q            = "sum:aws.rds.database_connections{host:${var.rds_cluster_resource_id}}"
            display_type = "area"
            style {
              palette    = "classic"
              line_type  = "solid"
              line_width = "thin"
            }
            metadata {
              expression = "sum:aws.rds.database_connections{host:${var.rds_cluster_resource_id}}"
              alias_name = "db connections"
            }
          }
        }
      } // w-1

      widget {
        timeseries_definition {
          title       = "rds iops"
          show_legend = true
          legend_size = "2"
          live_span   = "10m"
          request {
            q            = "sum:aws.rds.write_iops{host:${var.rds_cluster_resource_id}}.as_count(), sum:aws.rds.read_iops{host:${var.rds_cluster_resource_id}}.as_count()"
            display_type = "area"
            style {
              palette    = "classic"
              line_type  = "solid"
              line_width = "thin"
            }
            metadata {
              expression = "sum:aws.rds.write_iops{host:${var.rds_cluster_resource_id}}.as_count()"
              alias_name = "write IOPs"
            }
            metadata {
              expression = "sum:aws.rds.read_iops{host:${var.rds_cluster_resource_id}}.as_count()"
              alias_name = "read IOPs"
            }
          }
        }
      } // w-2

      widget {
        timeseries_definition {
          title       = "rds cpu utilization"
          show_legend = true
          legend_size = "2"
          live_span   = "10m"
          request {
            q            = "avg:aws.rds.cpuutilization{host:${var.rds_cluster_resource_id}}.as_count()"
            display_type = "area"
            style {
              palette    = "classic"
              line_type  = "solid"
              line_width = "thin"
            }
            metadata {
              expression = "avg:aws.rds.cpuutilization{host:${var.rds_cluster_resource_id}}.as_count()"
              alias_name = "cpu %"
            }

          }
        }
      } // w-3

      widget {
        timeseries_definition {
          title       = "rds deadlocks"
          show_legend = true
          legend_size = "2"
          live_span   = "10m"
          request {
            q            = "avg:aws.rds.deadlocks{host:${var.rds_cluster_resource_id}}.rollup(sum, 3600)"
            display_type = "area"
            style {
              palette    = "classic"
              line_type  = "solid"
              line_width = "thin"
            }
            metadata {
              expression = "avg:aws.rds.deadlocks{host:${var.rds_cluster_resource_id}}.rollup(sum, 3600)"
              alias_name = "deadlocks"
            }

          }
        }
      } // w-4

    }
  } // group-rds
}
