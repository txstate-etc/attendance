#!/bin/bash

trap killall SIGINT INT SIGHUP HUP SIGTERM TERM SIGQUIT QUIT

killall() {
	kill $HTTPDPID $CLEANERPID $GRADEPID
	exit
}

(/usr/sbin/apache2 -DFOREGROUND)&
HTTPDPID=$!

(
	while true; do
		if [[ `date +%H%M` == "0301" ]]; then
			rake db:nonce_clean
			rake db:session_clean DAYS=30
			for i in {1..60}; do sleep 1; done
		fi

		sleep 1
	done
)&
CLEANERPID=$!

(
	while true; do
		script/rails runner -e production Gradeupdate.update_sections_with_recent_meetings
		script/rails runner -e production Gradeupdate.process_all
		for i in {1..300}; do sleep 1; done
	done
)&
GRADEPID=$!


while true; do sleep 1; done
