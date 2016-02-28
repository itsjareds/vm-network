#!/bin/bash

if [[ $# -ne 3 ]] && [[ $# -ne 4 ]]; then
  echo "Invalid parameters"
  echo "Syntax: $0 experiment_number host_ip host_port [echo_port]"
  exit 1
fi

case "$1" in
  1) #UDP
    iperf3 -p $3 -c $2 -b 20m -u -i 1 -t 20
    ;;
  2) #TCP
    iperf3 -p $3 -c $2 -b 20m -i 1 -t 20
    ;;
  3) #UDP with echo program running
    if [[ $# -ne 4 ]]; then
      echo "Invalid parameters"
      echo "Syntax: $0 experiment_number host_ip host_port echo_port"
      exit 1
    fi
    for i in '1' '0.1' '0.01' '0.001'; do
      # modified client to output ping info to stderr
      ./client $2 $4 $i 1024 2>/dev/null &
      client=$!
      iperf3 -p $3 -c $2 -b 20m -u -i 1 -t 20
      kill -INT $client
    done
    ;;
  4) #TCP with echo program running
    if [[ $# -ne 4 ]]; then
      echo "Invalid parameters"
      echo "Syntax: $0 experiment_number host_ip host_port echo_port"
      exit 1
    fi
    for i in '1' '0.1' '0.01' '0.001'; do
      # modified client to output ping info to stderr
      ./client $2 $4 $i 1024 2>/dev/null &
      client=$!
      iperf3 -p $3 -c $2 -b 20m -i 1 -t 20
      kill -INT $client
    done
    ;;
  *)
    echo "Invalid experiment number"
    echo "Syntax: $0 experiment_number host_ip host_port [echo_port]"
    exit 1
esac
