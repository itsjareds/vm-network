#!/bin/bash

# read config file variables
source ./monitor.conf

root=($(df | awk '{ gsub(/%/, ""); if ($6 == "/") print $5 " " $3}'))
usage=${root[0]}
total=${root[1]}
echo "Disk usage on /: $usage%"

if [[ $usage -gt $threshold ]]; then
  echo "WARNING: disk usage threshold $threshold exceeded!"
  for user in /home/*; do
    du -s $user | awk -v total=$total '{ printf("%.1f%% %s\n", 100*$1/total, $2) }'
  done
fi


# The program aureport can be found in the 'auditd' package available
# in the standard Ubuntu repositories. It provides more comprehensive
# login attempt info than the difficult to analyze auth.log file.
echo
echo "Failed login attempts by user:"
echo "------------------------------"
sudo aureport -au -i --failed -ts yesterday $(date +%H:%M:%S) | tail -n+6 \
  | awk '{arr[$4]++} END{for (i in arr) print arr[i] " " i}' | sort -nr


# vnstat can similarly be installed via apt-get package 'vnstat'
echo
echo "Analyzing bandwidth usage by interface:"
echo "---------------------------------------"
ifaces=($(vnstat --iflist | cut -d' ' -f3- | tr " " "\n\r" | grep "^eth"))
for iface in ${ifaces[@]}; do
  echo
  echo "Bandwidth used over 5 seconds on interface $iface..."

  vals=($(IFS=$'\n' vnstat -tr -i $iface | tail -n+4 | grep -v -e '^[[:space:]]*$' | awk '{print $2 $3}'))

  eq=
  for val in ${vals[@]}; do
    eq+=$(units $val 'bits/s' | awk 'NR==1{print $2}')
    eq+=" + "
  done
  eq+="0"
  eq=$(echo "$eq" | sed -e 's/e+*/\*10\^/g')

  result=$(echo "scale=2; ($eq) / 1000" | bc -l)
  echo "$result kbits/s"

  if [[ $(echo $result '>' $bw_max | bc) -eq 1 ]]; then
    echo "WARNING: bandwidth threshold $bw_max kbits/s exceeded!"
  fi
done
