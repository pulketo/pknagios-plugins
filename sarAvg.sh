#!/bin/bash
#@pulketo
MYSELF=`basename $0`
#1#
#USER="sarmonitor"
#TARGET="10.10.3.5"
if [ -z "${1}" ]
then
	echo "$MYSELF NOK - Undefined user@targetip"
	exit 11
else
	  USER=`echo ${1}|cut -d "@" -f1`
	TARGET=`echo ${1}|cut -d "@" -f2`
	if [[ "$USER" == "" ]] || [[ "$TARGET" == "" ]]
	then
		echo "$MYSELF NOK - Undefined user@targetip"
		exit 11
	fi
fi
#2# ST,SC,LN
if [ -z "${2}" ]
then
	echo "$MYSELF NOK - Undefined SARTYPE,SARCOLUMN,LASTN"
	exit 12
else
	ST=`echo ${2}|cut -d "," -f1`
	SC=`echo ${2}|cut -d "," -f2`
	LN=`echo ${2}|cut -d "," -f3`
	if [[ "$ST" == "" ]] || [[ "$SC" == "" ]] || [[ "$LN" == "" ]]
	then
		echo "$MYSELF NOK - Undefined SARTYPE,SARCOLUMN,LASTN"
		exit 12
	fi
fi
#3# 
#OPERATOR="GTE"
if [ -z "${3}" ]
then
	echo "$MYSELF NOK - Undefined REL OPERATOR:lt|le|gt|ge|range"
	exit 13
else
	OP=`echo "${3}" | tr '[:lower:]' '[:upper:]'`
	list="LT LE GT GE RANGE"
	if [[ $list =~ (^|[[:space:]])$OP($|[[:space:]]) ]]
	then
		true
	else
		echo "$MYSELF NOK - Undefined REL OPERATOR should be UPPERCASE: $list"
		exit 13
	fi
fi
#4# C,W|C,W,W,C|W,C
if [ -z "${4}" ]
then
	echo "$MYSELF NOK - Undefined WARNING CRITICAL values: <C,W>|<C,W,W,C>|<W,C>"
	exit 14
else
	vcount=`echo ,${4} | grep -e ',' -o| wc -l`
#	echo "vcount:$vcount"
	cmpvcount=`echo "$vcount == 4 || $vcount ==2" | bc -l`
#.	echo "cmpvcount:$cmpvcount"
	if [ "$cmpvcount" == "0" ] 
	then
		echo "$MYSELF NOK - Incorrect number of parameters <C,W>|<C,W,W,C>|<W,C>"
		exit 15
	fi
###
# COMPARE NUMBER OF PARAMS VS OPERATOR
###	
case $OP in
	"RANGE")
		if [ "$vcount" != "4" ] 
		then
			echo "$MYSELF NOK - WARNING CRITICAL values doesn't correspond to OPERATOR $OP"
			exit 16
		fi
	;;

	*)
		if [ "$vcount" != "2" ] 
		then
			echo "$MYSELF NOK - WARNING CRITICAL values doesn't correspond to OPERATOR $OP"
			exit 16
		fi	
	;;
esac
######
	WC1=`echo ${4}|cut -d "," -f1`
	WC2=`echo ${4}|cut -d "," -f2`
	WC3=`echo ${4}|cut -d "," -f3`
	WC4=`echo ${4}|cut -d "," -f4`
	if [[ "$WC3" != "" ]] && [[ "$WC4" != "" ]]
	then
		#RANGE?
		CL=`echo $WC1+0|bc -l`
		WL=`echo $WC2+0|bc -l`
		WG=`echo $WC3+0|bc -l`
		CG=`echo $WC4+0|bc -l`
	else
		## C,W or W,C
		case $OP in
			LT|LE) 
				CL=`echo $WC1+0|bc -l`
				WL=`echo $WC2+0|bc -l`
				CMPWC1=`echo "$CL>$WL" | bc -l`
#				echo "CMPWC1:$CMPWC1"
				if [ "$CMPWC1" == "1" ]
				then
					echo "$MYSELF NOK - W<C not valid parameter"
					exit 18
				fi
			;;
			GT|GE)
				WG=`echo $WC1+0|bc -l`
				CG=`echo $WC2+0|bc -l`
				CMPWC2=`echo "$WG>$CG" | bc -l`
				# echo "CMPWC2:$CMPWC2"
				if [ "$CMPWC2" == "1" ]
				then
					echo "$MYSELF NOK - W>C not valid parameter"
					exit 18
				fi
			;;
			*)
				echo "$MYSELF NOK - OPERATOR doesn't comply with W,C values"
				exit 15
			;;
		esac
	fi
fi
######### RANGE inverted values 
if [ "$OP" == "RANGE" ]
then
	CMPRINV1=`echo "$CL>$WL" | bc -l`
	CMPRINV2=`echo "$WL>$WG" | bc -l`
	CMPRINV3=`echo "$WG>$CG" | bc -l`

	if [[ "$CMPRINV1" == 1 ]] || [[ "$CMPRINV2" == 1 ]] || [[ "$CMPRINV2" == 1 ]] ; then
		echo "$MYSELF NOK - RANGE values INVERTED"
		exit 18
	fi
fi
#########
if [ -z "${5}" ]
then
	echo "$MYSELF NOK - TIMEFRAME for ALARM not defined example: 12:00-14:59"
	exit 16
else
	tcount=`echo ${5} | grep -e '-' -o| wc -l`
	if [ $tcount != 1 ]
	then
		echo "$MYSELF NOK - Incorrect number of timeframe parameters example: 12:00-14:59"
		exit 17
	fi	
	ALARMTIMESTART=`echo "${5}" | cut -d "-" -f1`
	ALARMTIMEFINISH=`echo "${5}" | cut -d "-" -f2`
fi
currenttime="$(date +%H:%M)"
if [[ "$currenttime" > "$ALARMTIMESTART" ]] && [[ "$currenttime" < "$ALARMTIMEFINISH" ]]; then
	ALARM="ON"
else
	ALARM="OFF"
fi
#SSHPROXY
if [ -z "${6}" ]
then
	PROXY=0
else
	PROXY=1
	PUSER=`echo ${6}|cut -d "@" -f1`
		PIP=`echo ${6}|cut -d "@" -f2`
	pcount=`echo ${6} | grep -e '@' -o| wc -l`
	if [[ "$PUSER" == "" ]] || [[ "$PIP" == "" ]] || [[ "$pcount" != "1" ]]
	then
		echo "$MYSELF NOK - Incorrect parameter PROXYSSH example: user@10.x.y.z"
		exit 18
	fi
fi
######## Debug   ########
#echo "USER:$USER";echo "TARGET:$TARGET";echo "ST:$ST";echo "SC:$SC";echo "LN:$LN";echo "OP:$OP";echo "ALARM:$ALARM";echo "CL:$CL";echo "WL:$WL";echo "WG:$WG";echo "CG:$CG";echo "ALARMTIMESTART:$ALARMTIMESTART";echo "ALARMTIMEFINISH:$ALARMTIMEFINISH";echo "PROXY:$PROXY";echo "PUSER:$PUSER";echo "PIP:$PIP";
######## Connection ########
if [ "$PROXY" == 0 ]
then
	CMD="ssh ${USER}@${TARGET} \"sar -$ST\""
	EXE=`$CMD`	
	#	echo `$CMD`
else
	CMD="ssh -q -t ${PUSER}@${PIP} ssh -q ${USER}@${TARGET} 'LC_TIME=en_UK.utf8 sar -$ST|tail -n+3|grep -v ^[a-zA-Z]' 2>/dev/null ";
	EXE=`$CMD`	
fi
######## Extract information ########
HEADER=`echo "$EXE" | head -n1`
BODY=`echo "$EXE"|tail -n+2`
#echo "$BODY"
colname=`echo "$HEADER" | awk "{print \\$\$SC}"`
colout=`echo "$BODY" | awk "{print \\$\$SC}" | tail -n "\$LN"`
coljoined=`echo "$colout" | tr '\n' ','|sed 's/,$//g'`
#echo "$colout"
avg=`echo "$colout" |awk "{sum+=\\$1} END { print sum/NR}"`
avgT=`printf "%.2f" "$avg"`
########
ALARMSTATUS=0
STATUS="OK"
######## Alarm check ########
if [ "$OP" == "RANGE" ]
then
		CMPWG=`echo "$avg>$WG"| bc -l`
		CMPCG=`echo "$avg>$CG"| bc -l`
		CMPWL=`echo "$avg<$WL"| bc -l`
		CMPCL=`echo "$avg<$CL"| bc -l`
fi

if [ "$OP" == "GT" ]
then
		CMPWG=`echo "$avg > $WG"| bc -l`
		CMPCG=`echo "$avg > $CG"| bc -l`
fi

if [ "$OP" == "GE" ]
then
		CMPWG=`echo "$avg >= $WG"| bc -l`
		CMPCG=`echo "$avg >= $CG"| bc -l`
fi

if [ "$OP" == "LT" ]
then
		CMPWL=`echo "$avg < $WL"| bc -l`
		CMPCL=`echo "$avg < $CL"| bc -l`
fi

if [ "$OP" == "LE" ]
then
		CMPWL=`echo "$avg <= $WL"| bc -l`
		CMPCL=`echo "$avg <= $CL"| bc -l`
fi
####
#echo "CMPWL:$CMPWL";echo "CMPWG:$CMPWG";echo "CMPCL:$CMPCL";echo "CMPCG:$CMPCG"
#
if [ "$CMPWL" == 1 ] 
then
	ALARMSTATUS=1
	STATUS="WARNING INF"
	ERROR=1
fi

if [ "$CMPWG" == 1 ] 
then
	ALARMSTATUS=1
	STATUS="WARNING SUP"
	ERROR=1
fi

if [ "$CMPCG" == 1 ] 
then
	ALARMSTATUS=1
	STATUS="CRITICAL SUP"
	ERROR=2
fi

if [ "$CMPCL" == 1 ] 
then
	ALARMSTATUS=1
	STATUS="CRITICAL INF"
	ERROR=2
fi
   
####
if [ "$ALARM" == "ON" ]
then
	echo "$MYSELF $STATUS $colname=$avgT alarmByTime=$ALARM alarmed=$ALARMSTATUS | values=$coljoined OP=$OP WARNCRIT=${4}"
	exit $ERROR
else
	echo "$MYSELF OK $colname=$avgT alarmByTime=$ALARM couldBeAlarmed=$ALARMSTATUS | values=$coljoined OP=$OP WARNCRIT=${4}"
	exit 0
fi
