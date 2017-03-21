#!/bin/bash

#EXIT ON NONZERO response
set -e
#TRACE
set -x

set -- $(which redis-server) /usr/local/etc/redis/redis.conf

case $TYPE in
SLAVE)
echo "SLAVE"
echo "host=$hostname"
echo $(hostname | awk -F "." '{print $1}' | awk -F "-" '{print $4}')
master=$MASTER
host_number=$(hostname | awk -F "." '{print $1}' | awk -F "-" '{print $4}')
if [ "$host_number" -ne "0" ];
then
  master_host_number=$((($host_number-1)))
  master=$(hostname | sed "s/$host_number/$master_host_number/")
fi
# cat <<EOF >>/usr/local/etc/redis/redis.conf

# save 60 1
# dbfilename redis-slave-$host_number.rdp
# dir /var/redis-data
# EOF 
set -- $@ --slaveof $master 6379
cat /usr/local/etc/redis/redis.conf
;;
SENTINEL)

echo "SENTINEL!"
cat <<EOF >>/usr/local/etc/redis/redis.conf

sentinel monitor master $MASTER 6379 2
sentinel down-after-milliseconds master 300
sentinel failover-timeout master 300
sentinel parallel-syncs master 1
EOF
set -- $@ --port 26379 --sentinel
;;
MASTER)
echo "MASTER"
cat <<EOF >>/usr/local/etc/redis/redis.conf

save 60 1
dbfilename redis-master.rdp
dir /var/redis-data
EOF
;;
esac
exec "$@"
