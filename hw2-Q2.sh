#!/bin/bash

threshold=90
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
