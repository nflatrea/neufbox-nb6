#!/bin/sh
#
# for param in "$@"
# do
# 	rtk-switch phy power port$param down
# done





_manageLoop()
{
	PORTSLIST1=$(rtk-switch interrupt adv-info loop)

	#"LoopedList: port1 port4"

	if  test -n "$PORTSLIST1"
	then
		# replace "\n" with "".
		PORTSLIST2="$(echo -e $PORTSLIST1 | tr "\n" " ")"

		if  test -n "$PORTSLIST2"
		then
			# Split PORTLIST strings into LoopedList and ReleasedList.
			STRPART1="$(echo -e $PORTSLIST2 | tr "\n" " " | cut -d':' -f1)"
			STRPART2="$(echo -e $PORTSLIST2 | tr "\n" " " | cut -d':' -f2)"
			STRPART3="$(echo -e $PORTSLIST2 | tr "\n" " " | cut -d':' -f3)"

			if [ "$STRPART1" = "LoopedList" ]
			then
				LOOPED_PORTSLIST=${STRPART2/ReleasedList/""}
				RELEASED_PORTSLIST=$STRPART3
			else
				RELEASED_PORTSLIST=$STRPART2
				LOOPED_PORTSLIST=""
			fi

			# we need to filter if it's not a triggering event
			if [ "$LOOPED_PORTSLIST" != "$RELEASED_PORTSLIST" ]
			then
				# In this case a rising and falling edge have been detected
				if [ "$LOOPED_PORTSLIST" != "" ]
				then
					status set net_loop_interface "$PORTSLIST1"

					for param in $LOOPED_PORTSLIST
					do
						rtk-switch phy power $param down
						portDown=0
					done
				fi
			fi
		fi
	fi
}




_enableAllPort()
{
	for i in `seq 1 4`
	do
		rtk-switch phy power port$i up
	done

	status set net_loop_interface ""
}



portDown=1
i=0
blockTime=$(status get net_loop_resetCounter)
verifTime=$(status get net_loop_verificationTimer)

if [ -z $blockTime ] || [ $blockTime -lt 5 ]
then
	blockTime=5
fi

if [ -z $verifTime ] || [ $verifTime -lt 1 ]
then
	verifTime=5
fi


while true
do
	if [ $i -gt $blockTime ] && [ $portDown -eq 0 ]
	then
		i=0
		_enableAllPort
		portDown=1
	fi

	_manageLoop

	i=$((i+1))
	sleep $verifTime
done



