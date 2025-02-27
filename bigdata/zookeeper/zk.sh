#!/usr/bin/env bash

hosts=(kafka01 kafka02 kafka03)

case "$1" in
    'start')
        for host in "${hosts[@]}"; do
            echo "------------- zookeeper $host starting ------------"
            ssh "$host" "/opt/module/zookeeper-3.5.7/bin/zkServer.sh start"
        done
    ;;
    'stop')
        for host in "${hosts[@]}"; do
            echo "------------- zookeeper $host stopping ------------"
            ssh "$host" "/opt/module/zookeeper-3.5.7/bin/zkServer.sh stop"
        done
    ;;
    'status')
        for host in "${hosts[@]}"; do
            echo "------------- zookeeper $host status ------------"
            ssh "$host" "/opt/module/zookeeper-3.5.7/bin/zkServer.sh status"
        done
    ;;
esac