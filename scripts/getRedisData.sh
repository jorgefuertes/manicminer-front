#!/usr/bin/env bash

APPDIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
REMOTE="root@manicminer.in"
ORIG="/var/lib/redis/dump.rdb"
DEST="/usr/local/var/db/redis/."

source $APPDIR/functions.inc.sh

titulo "Import Production Redis Data"

haciendo "Saving remote data"
ssh $REMOTE redis-cli save &> /dev/null
ok $?

haciendo "Downloading"
scp $REMOTE:$ORIG $DEST &> /dev/null
ok $?

informa "Starting redis..."
redis-server /usr/local/etc/redis.conf

finalizado 0

