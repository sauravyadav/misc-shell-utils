#!/bin/bash                                                                    
#Version:  2.1                                                                    
#Info: Script to check the hardware health of Dell servers using Dell Server Admin   
#Author : Saurav Yadav 


#Check for dell server admin
if [ ! -d /opt/dell/srvadmin/ ]; then
          echo "Error: Can't found Dell open manage server admin directory, please install it"
          exit 1
fi

#Setting up the path variables
PATH=$PATH:/usr/bin:/opt/dell/srvadmin/bin/
export PATH

rm -f /tmp/omreport_*

#variables
storage=/tmp/omreport_storage.txt
chassis=/tmp/omreport_chassis.txt
raid=/tmp/omreport_raid.txt
alert_log=/tmp/omreport_alert_log.txt
esm_log=/tmp/omreport_esm_log.txt
cmd_log=/tmp/omreport_cmd_log.txt
ip=`/sbin/ifconfig eth0 | grep 'inet addr:' | cut -d ':' -f2 | cut -d ' ' -f1`
omreport=/tmp/omreport_full.$(date +%d-%m-%Y).txt
mailbody=/tmp/omreport_mail.txt
status=/tmp/omreport_status.txt
BackupServerIP=X.X.X.X
BackupServerPath="$BackupServerIP:/opt/checkserver"
mailid="infra-alerts@gmail.com"

#Check Storage Health
echo -e "--------------------------------------------------------------------------------------" >$mailbody
echo This is an automatically generated email by Dell Serveradmin from ${HOSTNAME}/$ip "(on $(date +%d-%m-%Y)" @ $(date +%H:%M)\), Please check the attached file for more details: >>$mailbody
echo -e "\n--------------------------------------------------------------------------------------\n\n" >>$mailbody
echo -e "Storage Health-------------------------------------------------------------------------------------------\n" >$storage
omreport storage controller |grep -E "^ID[[:space:]]+:[[:space:]]+[[:digit:]]{0,2}$" | cut -f2 -d ':' | while read i ;do omreport storage adisk controller=$i | grep -w -E "^(ID|Status|State|Failure Predicted)" ;done | sed '/Failure Predicted/a\ ' >>$storage

count=0
omreport storage controller |grep -E "^ID[[:space:]]+:[[:space:]]+[[:digit:]]{0,2}$" | cut -f2 -d ':' | while read i ;do omreport storage adisk controller=$i | grep -w -E "^Status" | cut -f2 -d ':' ;done >/tmp/tmp_storage_detail
cat /tmp/tmp_storage_detail | while read i ;do
read Status <<<$(echo "$i")
      echo "${Status}""       : Disk"${count#: }
((count++))
done >>$status
rm -f /tmp/tmp_storage_detail
echo -e "\n--------------------------------------------------------------------------------------------------------\n\n" >>$storage
count=0
omreport storage battery | grep -w -E "^(Status)" | cut -f2 -d ':' | while read i ;do
read Status <<<$(echo "$i")
echo ${Status}"       : Disk-battery"${count#: }
((count++))
done >>$status
echo -e "Storage Battery Health------------------------------------------------------------------------------------\n" >>$storage
omreport storage battery | grep -w -E "^(ID|Status|Name|State)" >>$storage
echo -e "\n--------------------------------------------------------------------------------------------------------\n\n" >>$storage

#Check System Information
omreport system |grep -E "^(Ok|Critical|Non-Critical)" >>$status
omreport chassis |grep -E '^(Ok|Critical|Non-Critical)' >>$status

echo -e "System Health---------------------------------------------------------------------------------------------\n" >$chassis
omreport system |grep -E "^(Ok|Critical|Non-Critical)" >>$chassis
omreport chassis |grep -E '^(Ok|Critical|Non-Critical)' >>$chassis
echo -e "\n--------------------------------------------------------------------------------------------------------\n\n" >>$chassis

#Raid Type and Size Information
echo -e "Raid Type and Size-----------------------------------------------------------------------------------------\n" >$raid
omreport storage controller |grep -E "^ID[[:space:]]+:[[:space:]]+[[:digit:]]{0,2}$" | cut -f2 -d ':' | while read i ;do omreport storage vdisk controller=$i | grep -w -E "^(Layout|Size)" ;done | sed '/Size/a\ ' >>$raid
echo -e "\n--------------------------------------------------------------------------------------------------------\n\n" >>$raid

#System Alertlog
echo -e "System Alertlog--------------------------------------------------------------------------------------------\n" >$alert_log
omreport system alertlog |grep -E -A5 "(Critical|Non-Critical)" >>$alert_log
echo -e "\n--------------------------------------------------------------------------------------------------------\n\n" >>$alert_log

#ESM Hardware log
echo -e "ESM Hardware log-------------------------------------------------------------------------------------------\n" >$esm_log
omreport system esmlog |grep -E -A5 "(Critical|Non-Critical)" >>$esm_log
echo -e "\n--------------------------------------------------------------------------------------------------------\n\n" >>$esm_log

#CMD log
echo -e "CMD log----------------------------------------------------------------------------------------------------\n" >$cmd_log
omreport system cmdlog |grep -E -A5 "(Critical|Non-Critical)" >>$cmd_log
echo -e "\n--------------------------------------------------------------------------------------------------------\n\n" >>$cmd_log

#Complete report in a single file:
cat $storage >$omreport
cat $chassis >>$omreport
cat $raid >>$omreport
cat $alert_log >>$omreport
cat $esm_log >>$omreport
cat $cmd_log >>$omreport

#Clear command, alert and hardware (Embedded System Management) log after each run for garbage cleaning
omconfig system cmdlog action=clear
omconfig system esmlog action=clear
omconfig system alertlog action=clear


#Sending mail to linuxops--
cat $status | while read i ;do
read Status COM <<<$(echo "$i")
    if [[ "${Status}" =~ 'Ok' ]] ; then
      echo ${COM#: }"   "${Status}
    elif [[ "${Status}" =~ 'Non-Critical' ]] ; then
      echo ${COM#: }"   "${Status}
    elif [[ "${Status}" =~ 'Critical' ]] ; then
        if [[ "${COM#: }" =~ 'Main\ System\ Chassis' ]] ;then
                echo "Issue in Main System Chasis but can be ignored due to multiple alerts !!"
        elif [[ "${COM#: }" =~ 'Disk-battery0' ]] ;then
                echo "Issue in Disk-battery0 but can be ignored !!"
        elif [[ "${COM#: }" =~ 'Disk-battery1' ]] ;then
                echo "Issue in Disk-battery1 but can be ignored !!"
        elif [[ "${COM#: }" =~ 'Power\ Supplies' ]] ;then
                echo "Issue in Power supply but can be ignored !!"
        else
                echo ${COM#: }" is "${Status} "Please check !!" >>$mailbody
                mutt -s "omreport: for `hostname`/$ip on $(date +%d-%m-%Y)" -a "$omreport" $mailid <$mailbody
        fi
    else
    echo "Got no data, please check your script and run again: "
fi
done
