#!/usr/bin/env bash

APPDIR="/home/padrino/manicminer-pool"
source /root/bin/functions.inc.sh

titulo "Checking thin instances"
informa "PID files:"

COUNT=0
cat $APPDIR/tmp/pids/thin.* &> /dev/null
if [[ $? -ne 0 ]]
then
	informa "Service stopped"
else
	for i in $(ls -C1 $APPDIR/tmp/pids/thin.*)
	do
		THIS_PID=$(cat $i)
		haciendo "PID ${THIS_PID}"
		ps aux|grep -v grep|grep $THIS_PID &> /dev/null
		RESULT=$?
		ok $RESULT
		if [[ $RESULT -eq 0 ]]
		then
   		    let COUNT++
        else
            haciendo "Deleting PID file ${i}"
            rm $i
            ok $?
        fi
	done
fi

informa "Active thin instances: ${COUNT}"
if [[ $COUNT -lt 8 ]]
then
    aviso "Less than 8 instances!"
    $APPDIR/scripts/app-server.sh restart
else
    informa "All instances UP"
fi

informa "Sleeping 120 seconds"
sleep 120
