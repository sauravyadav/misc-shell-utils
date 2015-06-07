#### misc-shell-utils

#####omreport.sh
- Script to monitor the health of ``dell servers`` using dell server admin and send you the email report in case of any issues in any hardware.
    - Monitor ``CPU, Disk, Memory, Temp`` etc..
  
  ``crontab:``
  ```
  00 */12 * * * /bin/bash /custom-scripts/omreport.sh
  ```
  
#####top10.sh
- Script to monitor the Apache/Nginx logs every hour and send you a notification incase someone sending too many requests.
    - You can set the threshold  value in script.
  ``crontab:``
  ```
  00 * * * * /bin/bash /custom-scripts/omreport.sh
  ```

#####puppet-sync.sh
- Script to execute the ``puppetrun`` on all the host & push the changes in ``git`` master.
    - You need to change the path and URLs according to your environment.
    
#####checktag.sh
- Script to monitor the new git tags on all the ``gitlab`` repos and trigger the ``Jenkins`` jobs for deployment & QC automation.
    - You need to change the path and URLs according to your environment.
