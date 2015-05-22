#!/bin/bash
#Version:  1.0                                                                    
#Info: Script to execute the puppetrun on all the host & push the changes in git master.
#Author : Saurav Yadav 

source /custom-scripts/ignore-server
cat /var/lib/puppet/ssl/ca/inventory.txt | cut -f2 -d '=' | grep -E -v $host | uniq -u | while read i
do
puppetrun --parallel 1 --host $i >>/dev/null 2>/dev/null
done

cd /etc/puppet
git add *
who=`last | grep -v 'noc' | head -n1 | gawk {'print $1'}`
git commit -am "Changes done in Puppet repo @ `date +"%Y%m%d"` by $who" >>/dev/null
git push origin --all >>/dev/null

curr_revision=`git log | grep -w "commit" | head -n2 | head -n1 | gawk {'print $2'}`
last_revision=`git log | grep -w "commit" | head -n2 | tail -n1 | gawk {'print $2'}`

echo -e "Configuration files updated on Puppet server, Kindly review your changes at below mention url::\nhttp://gitmaster.domain.com/?p=repositories/puppet.git;a=commitdiff;h=$curr_revision;hp=$last_revision \n\nNOTE::This mail is generated by Puppet, Please do not reply on this mail!! \n\n --\nThanks \n TechOPS" | mail -s "configuration file updated on puppetmaster @`date` !!" email-id@gmail.com
