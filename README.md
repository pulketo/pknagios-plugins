# pknagios-plugins
My own nagios plugins, some stuff I need, and haven't find something already done
-------------------------------------------------------------------------------------
Manual for sarAvg.sh
T*he problem: 
Say you have detected that some system normal behavior for %iowait by time is:
00:00-03:50 < 5.00%
04:00-05:30 > 15.00%
05:40-21:30 < 5%
21-30-22:30 < 15%
22:30-23:50 >5% and <15%
Help for detecting these percentages: https://gist.githubusercontent.com/pulketo/192fa5217143b0745045e35899f81f50/raw/a9c30ed68007b6d4600a4e7136fa58944ed4fef1/gistfile1.txt
The solution: sarAvg.sh
Lets take 04:00-05:30, should be >15% (in my case if this is not the case, then something is wrong) so:
sound the alarm if: the last 3 values of the 6th column of sar -p from 04:20 to 05:30 drops below 10 or critical if drops below 8
sarAvg.sh sarmonitor@10.10.3.5 p,6,3 LT 8,10 04:20-05:30 sarmonitor@10.1.91.100
                            
sarAvg.sh user@target.ip ST,SC,LN COMP WARNCRIT XX:XX-YY:YY sshproxy@sshproxy.ip
user@target.ip -> ssh connection 
ST,SC,LN
|  |   +--average the last 3 values
|  +------6th column = IOwait
+---------which sar statitistics to show valid value:p,q,b,B,d,etc... (*)
COMP: GT,GE,LE,LT,RANGE,todo:RANGEOUT
WARNCRIT: 
  +-> Valid values for LT,LE: Critical,Warning example: 10,8 
  +-> Valid values for GT,GE: Warning,Critical example: 8,10
  +-> Valid values for RANGE: Critical,Warning,Warning,Critical example: 1,2,5,6
ALARMTIME: XX:XX-YY:YY
  +-> StartHour:XX:XX
  +-> EndHour:YY:YY
sshproxy@sshproxy.ip->jump ssh

(*) i know i know -p option could be used with all the other options... let's just say -p is for: sar without arguments
  


--------------------------------------------------------------------------------------
