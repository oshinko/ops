if [ -z "$SERVICE_NAME" ]; then
  echo '$SERVICE_NAME is required'
  exit 1
fi

if [ -z "$SERVICE_DESCRIPTION" ]; then
  echo '$SERVICE_DESCRIPTION is required'
  exit 1
fi

if [ -z "$SERVICE_WORKING_DIRECTORY" ]; then
  echo '$SERVICE_WORKING_DIRECTORY is required'
  exit 1
fi

if [ -z "$SERVICE_EXEC_START" ]; then
  echo '$SERVICE_EXEC_START is required'
  exit 1
fi

if [ -z "$SERVICE_RESTART" ]; then
  SERVICE_RESTART=always
fi

if [ -z "$SERVICE_TYPE" ]; then
  SERVICE_TYPE=simple
fi

if [ -z "$SERVICE_USER" ]; then
  SERVICE_USER=`whoami`
fi

echo "Initial Parameters"
echo "  SERVICE_NAME: $SERVICE_NAME"
echo "  SERVICE_DESCRIPTION: $SERVICE_DESCRIPTION"
echo "  SERVICE_WORKING_DIRECTORY: $SERVICE_WORKING_DIRECTORY"
echo "  SERVICE_EXEC_START: $SERVICE_EXEC_START"
echo "  SERVICE_RESTART: $SERVICE_RESTART"
echo "  SERVICE_TYPE: $SERVICE_TYPE"
echo "  SERVICE_USER: $SERVICE_USER"
echo

sudo bash -c "cat << EOF > /etc/systemd/system/$SERVICE_NAME.service
[Unit]
Description=$SERVICE_DESCRIPTION

[Service]
WorkingDirectory=$SERVICE_WORKING_DIRECTORY
ExecStart=$SERVICE_EXEC_START
EnvironmentFile=$SERVICE_ENVIRONMENT_FILE
Restart=$SERVICE_RESTART
Type=$SERVICE_TYPE
User=$SERVICE_USER

[Install]
WantedBy=multi-user.target
EOF"
sudo systemctl daemon-reload
sudo systemctl enable $SERVICE_NAME.service
sudo systemctl restart $SERVICE_NAME.service
