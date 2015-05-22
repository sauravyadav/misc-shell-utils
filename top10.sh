#!/bin/bash                                                                    
#Version:  1.0                                                                    
#Info: Script to send the top hitting IPs to system administrator.
#Author : Saurav Yadav 
server_ip=`ifconfig eth0 | grep -w inet | cut -d: -f2 | cut -f1 -d " "`
mailid="email-id@gmail.com"
DATE=`date +%Y%m%d`
cd /usr/local/apache2/logs
FILE=`ls -lhtr access_log* | tail -n1 | gawk {'print $9'}`
TEN=`sort -nr $FILE | grep \`date +%d/%b/%Y:%H --date="1 hours ago"\` | cut  -d " "  -f1  | uniq -c | sort -nr | head -n10`
echo "$TEN \n" | while read i ;do
        read Count IP <<<$(echo "$i")
                if [[ "${Count}" -gt '5000' ]] ; then
                        if [[ "$IP" == "-" ]] || [[ "$IP" == "127.0.0.1" ]] || [[ "$IP" == "- n" ]]; then
                        echo "do nothing"
                        else
                        echo -e "<h4>IP: ${IP}</h4>            <b><h4>hits: ${Count}</h4></b> \n\n\n http://www.whois.net/ip-address-lookup/${IP} \n\n http://whois.domaintools.com/${IP}"  | mail   -s "$(echo -e "Top hitting IP on $server_ip\nContent-Type: text/html")" $mailid
                        fi
                fi

done
