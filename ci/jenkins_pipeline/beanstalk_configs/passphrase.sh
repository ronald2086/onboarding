#!/bin/bash
/opt/elasticbeanstalk/bin/get-config environment | jq -r 'to_entries | .[] | "\(.key)=\(.value)"'| awk -F "=" '{if($1 == "ems.uuid") print $2}'
