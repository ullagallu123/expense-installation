#!/bin/bash
source ./common.sh

check_root
update_packages

dnf install mysql -y >> "$LOGFILE" 2>&1
VALIDATE $? "Installing MySQL client"

dnf module disable nodejs -y >> "$LOGFILE" 2>&1
VALIDATE $? "Disabling default NodeJS module"

dnf module enable nodejs:20 -y >> "$LOGFILE" 2>&1
VALIDATE $? "Enabling NodeJS 20 module"

dnf install nodejs -y >> "$LOGFILE" 2>&1
VALIDATE $? "Installing NodeJS 20"

# Check if the user 'expense' exists
id expense &>/dev/null
if [ $? -eq 0 ]; then
  echo "User 'expense' already exists" | tee -a "$LOGFILE"
else
  useradd expense >> "$LOGFILE" 2>&1
  VALIDATE $? "Adding user 'expense'"
fi

# Check if the /app directory exists
if [ -d "/app" ]; then
  echo "/app directory already exists" | tee -a "$LOGFILE"
else
  mkdir /app >> "$LOGFILE" 2>&1
  VALIDATE $? "Creating /app directory"
fi

# Check if the repository is already cloned
if [ -d "/app/.git" ]; then
  echo "Repository already cloned in /app" | tee -a "$LOGFILE"
else
  git clone https://github.com/ullagallu123/expense-backend.git /app >> "$LOGFILE" 2>&1
  VALIDATE $? "Cloning backend code from GitHub to /app directory"
fi

cd /app >> "$LOGFILE" 2>&1
npm install >> "$LOGFILE" 2>&1
VALIDATE $? "Installing application dependencies"

cat <<EOF > /etc/systemd/system/backend.service
[Unit]
Description=Backend Service

[Service]
User=expense
Environment=DB_HOST="expense.db.test.ullagallu.cloud"
ExecStart=/bin/node /app/index.js
SyslogIdentifier=backend

[Install]
WantedBy=multi-user.target
EOF
VALIDATE $? "Creating backend service file"

systemctl daemon-reload >> "$LOGFILE" 2>&1
VALIDATE $? "Reloading systemd daemon"

systemctl start backend >> "$LOGFILE" 2>&1
VALIDATE $? "Starting backend service"

systemctl enable backend >> "$LOGFILE" 2>&1
VALIDATE $? "Enabling backend service"

mysql -h expense.db.test.ullagallu.cloud -uroot -pExpenseApp1 < /app/schema/backend.sql >> "$LOGFILE" 2>&1
VALIDATE $? "Loading database schema"

systemctl restart backend >> "$LOGFILE" 2>&1
VALIDATE $? "Restarting backend service"

echo -e "$G All tasks completed successfully! $N" | tee -a "$LOGFILE"