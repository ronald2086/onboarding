#!/bin/bash
#check the postgres running before restoring
file=$1
UPGRADESQLPATH=/tmp/ems/home/enlighted/upgradeSQL.sql
is_running=`ps aux | grep -v grep | grep postgres | wc -l | awk '{print $1}'`
if [ $is_running != "0" ] ;
then
echo "Service postgres is running"
else
echo "Service postgres is not running. Starting the service..."
/etc/init.d/postgresql start
echo "Started the service"
fi
#Restore the database
if [ -f $file ]; then
    echo "Backup file existing proceeding with restore.."
    psql -U postgres -p 5433 -f $file
    echo "Restored successfully.."
    echo "Checking the connection status of the EMS.."
    pg_isready -h localhost -p 5433 -d ems
    if [ $? -eq 0 ]; then
        echo "Connection is Open.."
    else
        echo "Connection Failed. Please verify the logs.."
    fi
fi