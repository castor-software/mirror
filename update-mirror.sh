#!/bin/bash

#in: json description of asso repo src [mirrors]
#action: for all src 
#			if local copy does not exist git clone and add remote
#			git pull;
#			for all mirror
#				git push
#requires: jq, git
scriptPath=$0
oldWorkingDir=`pwd`
workingDir="."

if [[ "$scriptPath" == *"/"* ]]; then
    scriptName=`echo $scriptPath | rev | cut -d '/' -f1 | rev`
	workingDir=`echo $scriptPath | sed "s/$scriptName//g"`
	
fi

cd $workingDir

MIRRORS_LIST="mirror-list.json"
ABSOLUTE_PATH_OF_LOCAL_REPOS=`pwd`
LOG_FILE="logs"


cd $ABSOLUTE_PATH_OF_LOCAL_REPOS

echo " ### Start updates ### " >> $LOG_FILE
date >> $LOG_FILE

#For all repo to mirror
for rep in `cat $MIRRORS_LIST | jq -r '.[] | "\(.src)"'`
do
	cd $ABSOLUTE_PATH_OF_LOCAL_REPOS
	u=`echo $rep | cut -d '/' -f1`
	r=`echo $rep | cut -d '/' -f2`
	echo "Repo: $rep"

	mirrors=`cat $MIRRORS_LIST | jq -r ".[] | select(.src==\"$rep\") | \"\(.mirrors)\""`
	echo " -> mirrors: $mirrors"

	#If local copy does not exists
	if [ ! -d "$r" ]; then
		echo "$ABSOLUTE_PATH_OF_LOCAL_REPOS/$r does not exist."
		git clone ssh://github.com/$u/$r.git 2>&1
	fi
	cd $r

	git pull 2>&1 

	#For all mirror
	for m in `echo $mirrors | jq -r '.[]'`
	do
		echo "    mirror: $m"
		remote_u=`echo $m | cut -d '/' -f1`
		remote_r=`echo $m | cut -d '/' -f2`
		
		#if mirror is new
		git remote get-url $remote_u 2>&1
		if [ $? -ne 0 ]; then
			echo "Mirror $remote_u not registered yet"
			git remote add $remote_u ssh://github.com/$remote_u/$remote_r.git 2>&1
		fi

		#push to mirror
		git push $remote_u master 2>&1
	done
done >> $LOG_FILE
cd $oldWorkingDir
