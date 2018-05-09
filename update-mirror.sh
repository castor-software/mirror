#!/bin/bash

#in: json description of asso repo src [mirrors]
#action: for all src 
#			if local copy does not exist git clone and add remote
#			git pull;
#			for all mirror
#				git push
#requires: jq, git

MIRRORS_LIST="/home/nharrand/Documents/docs/mirror-list.json"
ABSOLUTE_PATH_OF_LOCAL_REPOS="/home/nharrand/Documents/docs"
LOG_FILE="/home/nharrand/Documents/docs/logs"


cd $ABSOLUTE_PATH_OF_LOCAL_REPOS

echo " ### Start updates ### " >> $LOG_FILE
date >> $LOG_FILE

#For all repo to mirror
for rep in `cat $MIRRORS_LIST | jq -r '.[] | "\(.src)"'`
do
	cd $ABSOLUTE_PATH_OF_LOCAL_REPOS
	u=`echo $rep | cut -d '/' -f1`
	r=`echo $rep | cut -d '/' -f2`
	echo "Repo: $rep" >> $LOG_FILE

	mirrors=`cat $MIRRORS_LIST | jq -r ".[] | select(.src==\"$rep\") | \"\(.mirrors)\""`
	echo " -> mirrors: $mirrors" >> $LOG_FILE

	#If local copy does not exists
	if [ ! -d "$r" ]; then
		echo "$ABSOLUTE_PATH_OF_LOCAL_REPOS/$r does not exist." >> $LOG_FILE
		git clone git@github.com:$u/$r.git >> $LOG_FILE 2>&1
	fi
	cd $r

	git pull >> $LOG_FILE 2>&1

	#For all mirror
	for m in `echo $mirrors | jq -r '.[]'`
	do
		echo "    mirror: $m" >> $LOG_FILE
		remote_u=`echo $m | cut -d '/' -f1`
		remote_r=`echo $m | cut -d '/' -f2`
		
		#if mirror is new
		git remote get-url $remote_u >> $LOG_FILE 2>&1
		if [ $? -ne 0 ]; then
			echo "Mirror $remote_u not registered yet" >> $LOG_FILE
			git remote add $remote_u git@github.com:$remote_u/$remote_r.git >> $LOG_FILE 2>&1
		fi

		#push to mirror
		git push $remote_u master >> $LOG_FILE 2>&1
	done
done
