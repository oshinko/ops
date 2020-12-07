if [ -z "$REMOTE" ]; then
  echo '$REMOTE is required'
  exit 1
fi

if [ -z "$SERVER" ]; then
  echo '$SERVER is required'
  exit 1
fi

if [ -z "$PORT" ]; then
  PORT=80
fi

if [ -n "$KEYPAIR" ]; then
  KEYPAIR_OPTION="-i $KEYPAIR"
fi

if [ -z "$PACKAGE" ]; then
  echo '$PACKAGE is required'
  exit 1
fi

if [ -z "$APP" ]; then
  echo '$APP is required'
  exit 1
fi

here=`dirname $0`

SERVER_HOME=/usr/share/nginx-servers/$SERVER/$PORT

cat $here/install/git-on-linux.sh | ssh $KEYPAIR_OPTION $REMOTE sh

cat $here/install/python-on-linux.sh | ssh $KEYPAIR_OPTION $REMOTE sh

VENV=$SERVER_HOME/venv

UPSTREAM_SERVER=unix:$SERVER_HOME/gunicorn.sock

WORKING_DIRECTORY=$SERVER_HOME/work

ENVIRONMENT_FILE_=$SERVER_HOME/env

cat << EOF | ssh $KEYPAIR_OPTION $REMOTE sh
sudo mkdir -p $SERVER_HOME
sudo chown -R \`whoami\` $SERVER_HOME
python3 -m venv $VENV
$VENV/bin/python -m pip install -U gunicorn $PACKAGE
mkdir -p $WORKING_DIRECTORY
touch $ENVIRONMENT_FILE_
EOF

if [ -n "$ENVIRONMENT_FILE" ]; then
  scp $KEYPAIR_OPTION $ENVIRONMENT_FILE $REMOTE:$ENVIRONMENT_FILE_
fi

cat $here/init/systemd.sh \
  | ssh $KEYPAIR_OPTION $REMOTE \
    SERVICE_NAME=$SERVER-$PORT \
    SERVICE_DESCRIPTION=\"$DESCRIPTION\" \
    SERVICE_WORKING_DIRECTORY=$WORKING_DIRECTORY \
    SERVICE_EXEC_START=\"$VENV/bin/gunicorn $APP --bind $UPSTREAM_SERVER\" \
    SERVICE_ENVIRONMENT_FILE=$ENVIRONMENT_FILE_ \
    sh

cat $here/init/nginx-on-linux.sh \
  | ssh $KEYPAIR_OPTION $REMOTE \
    NGINX_SERVER_NAME=$SERVER \
    NGINX_PORT=$PORT \
    NGINX_UPSTREAM_SERVER=$UPSTREAM_SERVER \
    NGINX_BASIC_AUTH_USER=$USER \
    NGINX_BASIC_AUTH_PASS=$PASS \
    NGINX_TRY_FILES=$TRY_FILES \
    sh
