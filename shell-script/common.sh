#!/bin/bash
USERID=$(id -u)
TIMESTAMP=$(date +%F-%H-%M-%S)
SCRIPT_NAME=$(basename $0 | cut -d "." -f1)
LOGFILE=/tmp/$SCRIPT_NAME-$TIMESTAMP.log
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

VALIDATE(){
   if [ $1 -ne 0 ]
   then
        echo -e "$2...$R FAILURE $N"
        exit 1
    else
        echo -e "$2...$G SUCCESS $N"
    fi
}

check_root(){
    if [ $USERID -ne 0 ]
    then
        echo "Please run this script with root access."
        exit 1
    fi
}

update_packages(){
    dnf update -y >> $LOGFILE 2>&1
    VALIDATE $? "Updating Packages"
}