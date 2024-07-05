#!/bin/bash

source ./common.sh

check_root
update_packages

dnf install nginx -y >> "$LOGFILE" 2>&1
VALIDATE $? "Installing Nginx"

systemctl enable nginx >> "$LOGFILE" 2>&1
VALIDATE $? "Enabling Nginx"

systemctl start nginx >> "$LOGFILE" 2>&1
VALIDATE $? "Starting Nginx"

rm -rf /usr/share/nginx/html/* >> "$LOGFILE" 2>&1
VALIDATE $? "Removing default Nginx content"


if [ -d "/usr/share/nginx/html/.git" ]; then
  echo "Repository already cloned in /usr/share/nginx/html" | tee -a "$LOGFILE"
else
  git clone https://github.com/ullagallu123/expense-frontend.git /usr/share/nginx/html >> "$LOGFILE" 2>&1
  VALIDATE $? "Cloning frontend code from GitHub to Nginx directory"
fi

cat <<EOF > /etc/nginx/default.d/expense.conf
server {
    listen 80 default_server;
    server_name localhost;

    root /usr/share/nginx/html;
    index index.html;

    location / {
        try_files  / =404;
    }

    location /api/ {
        proxy_pass http://expense.backend.test.ullagallu.cloud:8080/;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location /health {
        stub_status on;
        access_log off;
    }

    # Additional location blocks or configurations can go here
}

EOF
VALIDATE $? "Creating Nginx reverse proxy configuration"

systemctl restart nginx >> "$LOGFILE" 2>&1
VALIDATE $? "Restarting Nginx"

echo -e "$G All tasks completed successfully! $N"




