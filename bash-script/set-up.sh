#!/bin/bash

## This script modefied by javid

############################## HELP ############################
# -a  : start all task                 

# -t  : apply changes start threat-intelligence.timer service

# -s  : apply changes start threat-intelligence.service service

# -gt : get time for timer

# -b  : build golang code

# -sc : start containers

# -tc : stop containers

# -dc : down containers

# -dcv : down -v containers
################################################################


TIME="*-*-* 02:00:00"

main () {

    if [ $# -eq 0 ];
    then
        echo -e "\ninput parameter error!\nused bellow input parameter\n"
        help
        exit 0
    fi

    for var in "$@";
    do
        case $var in
            -a)
                start-all-task
                ;;
            -gt)
                get-OnCalendar
                start-threat-intelligence-timer-service
                set-up-systemctl
                ;;
            -b)
                build
                ;;
            -sc)
                start-container
                ;;
            -uc)
                up-container
                ;;
            -tc)
                stop-container
                ;;
            -dc)
                down-container
                ;;
            -dcv)
                downv-container
                ;;
            -h)
                help
                ;;
            *)
                echo -e "\ninput parameter invalid: $var\n"
                help
                exit 0
        esac
    done
}

start-all-task () {
    build
    start-threat-intelligence-service
    start-threat-intelligence-timer-service
    set-up-systemctl
    up-container
}

build () {
    DIR="/tmp/log_threat/"
    if [ ! -d "$DIR" ]; then
        mkdir -p $DIR &> /dev/null && chmod 777 $DIR
    fi

    go build ../go/api.go
    cp ./api /usr/bin && mv ./api /usr/local/bin
}

set-up-systemctl () {
    systemctl daemon-reload
    systemctl enable threat-intelligence.service
    systemctl enable threat-intelligence.timer
    systemctl reload-or-restart threat-intelligence.timer
}

down-container () {
    docker-compose -f ../elastic-docker-compose/docker-compose.yml down
}

downv-container () {
    docker-compose -f ../elastic-docker-compose/docker-compose.yml down -v
}

up-container () {
    docker-compose -f ../elastic-docker-compose/docker-compose.yml up -d
}

start-container () {
    docker-compose -f ../elastic-docker-compose/docker-compose.yml start
}

stop-container () {
    docker-compose -f ../elastic-docker-compose/docker-compose.yml stop
}

start-threat-intelligence-timer-service() {
touch /etc/systemd/system/threat-intelligence.timer
echo -e ""
cat << EOF > /etc/systemd/system/threat-intelligence.timer
[Unit]
Description="This service timer used for threat-intelligence.service"

[Timer]
OnCalendar=$TIME
Unit=threat-intelligence.service

[Install]
WantedBy=multi-user.target
EOF
}

start-threat-intelligence-service() {
touch /etc/systemd/system/threat-intelligence.service
cat << EOF > /etc/systemd/system/threat-intelligence.service
[Unit]
Description="This service run /usr/bin/api for fetch any info from api"
After=network.target
Requires=threat-intelligence.timer

[Service]
User=root
Group=root
WorkingDirectory=/usr/ 
ExecStart=/usr/bin/api  /usr/local/bin
Restart=on-abnormal
StandardOutput= file:/tmp/threat-intelligence.log

[Install]
WantedBy=multi-user.target
EOF
}

get-OnCalendar () {
    read -p "enter time pattern: " TIME
}

help () {
    echo -e "\t------------------HELP---------------------"
    echo -e "\t-a   : start all task"
    echo -e "\t-t   : apply changes and start threat-intelligence.timer service"
    echo -e "\t-s   : apply changes and start threat-intelligence.service service"
    echo -e "\t-gt  : get time for timer"
    echo -e "\t-b   : build golang code"
    echo -e "\t-uc  : up containers"
    echo -e "\t-sc  : start containers"
    echo -e "\t-tc  : stop containers"
    echo -e "\t-dc  : down containers"
    echo -e "\t-dcv : down -v containers\n"
}

main $@