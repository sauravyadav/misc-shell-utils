#!/bin/bash
#Version:  1.0                                                                    
#Info: Script to monitor the new git tags on all the gitlab repos and trigger the Jenkins jobs for deployment & QC automation.
#Author : Saurav Yadav 

cat /custom-scripts/repo_name | while read i ;
do repo_name=$i;

mkdir -p /var/tmp/jenkins/status/

taginfo=/var/tmp/jenkins/$repo_name-taginfo

lasttag=`cat /var/tmp/jenkins/$repo_name-tag`
lasttagtime=`cat /var/tmp/jenkins/$repo_name-tagtime`

exectime=`date +"%Y%m%d%H%M%S"`
echo $exectime >/var/tmp/jenkins/$repo_name-last


newtag=`ls -lhtr /var/opt/gitlab/git-data/repositories/$repo_name.git/refs/tags | awk '$9~"^jcb"' | gawk {'print $9'} | tail -n1`
newtagtime=`ls -lhtr /var/opt/gitlab/git-data/repositories/$repo_name.git/refs/tags | awk '$9~"^jcb"' | gawk {'print $8'} | tail -n1`

if [ -z "$newtag" ] ; then
newtag="none-or-empty"
fi

touch_app=true

if [ "$lasttag" == "$newtag" ] && [ "$lasttagtime" == "$newtagtime" ] ; then
echo "do nothing" >>/var/tmp/jenkins/$repo_name-last
else
echo $newtag > /var/tmp/jenkins/$repo_name-tag
echo $newtagtime > /var/tmp/jenkins/$repo_name-tagtime

touch_count=`echo $newtag | grep notouch | wc -l`

if [ $touch_count -gt 0 ]; then
touch_app=false
fi

>$taginfo

echo "=========================================================================">>$taginfo
cd /var/opt/gitlab/git-data/repositories/$repo_name.git
git show $newtag --format=full | head -n7 | grep -v "diff --git" >>$taginfo
echo "Tag: $newtag">>$taginfo
commit=`git show $newtag --format=full | head -n1 | gawk {'print $2'}`
echo " " >>$taginfo
echo "Kindly check the changes @ below URL::">>$taginfo
echo "http://gitlab.domain.com/$repo_name/commits/$commit" >>$taginfo
echo "=========================================================================">>$taginfo

author_name=`git show $newtag | grep -w 'Author:' | cut -f2 -d'<' | cut -f1 -d'>'` >>$taginfo
echo " " >>$taginfo

## Job status check on jenkins ##
## Moved the next 7 line logic to Jenkins
#sh /custom-scripts/checkstatus.sh $repo_name
#running=`cat /var/tmp/jenkins/status/$repo_name`

#while [ "$running" == "true" ]; do
#sleep 60s
#sh /custom-scripts/checkstatus.sh $repo_name
#running=`cat /var/tmp/jenkins/status/$repo_name`
#done

## GIT Sync & Code deployment ##
ssh -t root@10.100.2.51 "sh /git/$repo_name/git-sync" | tail -n5 >>$taginfo
authoremail=`ssh -t root@10.100.2.51 "cd /git/$repo_name/ ; git show $tagtodeploy | grep -w 'Author:' | cut -f2 -d'<' | cut -f1 -d'>'"`
count_merge=`cat $taginfo | grep "needs merge" | wc -l`
if [ $count_merge -gt 0 ]; then
echo "Deployment failed Please check !!" >>$taginfo
mail -s "[[:Deployment failed while code syncing:]]newtag-$newtag created on $repo_name @ $exectime" email-id@gmail.com $authoremail <$taginfo
exit 1
fi

sleep 2s
echo "Build started on jenkins, check the url http://10.100.2.69:8080/job/PP-$repo_name for progress....." >>$taginfo

### Jenkins setting ####
url="http://gojenkins:password123@10.100.2.69:8080/job/PP-$repo_name/buildWithParameters?delay=0sec&tagtodeploy=$newtag&touch=$touch_app"
curl -X POST "$url"

sed -i -e 's/[\x01-\x1F\x7F]//g' $taginfo

mail -r jenkins@gmail.com -s "[[:Build Started:]]newtag-$newtag created on $repo_name @ $exectime" email-id@gmail.com $authoremail <$taginfo

fi
done
