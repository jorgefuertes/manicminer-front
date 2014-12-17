#!/usr/bin/env bash

APPDIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
DBNAME="manicminer_pool_production"
DEVNAME="manicminer_pool_development"

source $APPDIR/functions.inc.sh

titulo "Import Production Database"
echo -e "$(bg_color red)+---------------------------------------+$(bg_color black)"
echo -e "$(bg_color red)|PLEASE: EXECUTE THIS AT DEVEL ENV ONLY!|$(bg_color black)"
echo -e "$(bg_color red)+---------------------------------------+$(bg_color black)"

sino "Continue and overwrite local data?"
if [[ $? -ne 0 ]]
then
	aviso "Aborted"
	finalizado
fi

haciendo "Dumping database"
ssh manicminer.in "mongodump -d ${DBNAME} &> /dev/null"
ok $?
haciendo "Crunching dumped data"
ssh manicminer.in "tar czf mongodump.tar.gz dump"
ok $?
haciendo "Downloading"
scp -q manicminer.in:/root/mongodump.tar.gz .
ok $?
haciendo "Decrunch data"
tar xzf mongodump.tar.gz && rm mongodump.tar.gz
ok $?

haciendo "Import database into local mongo"
mongorestore --drop -d $DEVNAME dump/$DBNAME &> /dev/null
ok $?

haciendo "Removing dump dir"
rm -Rf dump
ok $?

finalizado 0

