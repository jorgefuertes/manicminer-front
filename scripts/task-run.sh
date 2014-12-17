#!/bin/bash

export HOME="/home/padrino"
export PATH="/usr/local/rvm/gems/ruby-2.1.0/bin:/usr/local/rvm/gems/ruby-2.1.0@global/bin:/usr/local/rvm/rubies/ruby-2.1.0/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/local/rvm/bin"
export GEM_PATH="/usr/local/rvm/gems/ruby-2.1.0:/usr/local/rvm/gems/ruby-2.1.0@global"

TASK=$1

while [[ 1 ]]
do
	echo "Cheking for running ${TASK}"
	ps aux|grep rake|grep $TASK
	if [[ $? -eq 0 ]]
	then
		echo "Another instance is running!"
		echo "Waiting 10 seconds"
		sleep 10
	else
		cd /home/padrino/manicminer-pool
		padrino rake -e production $TASK
		echo "Wait 60 seconds to respawn..."
		sleep 60
	fi
done

echo "Unexpected exit!"
exit 1
