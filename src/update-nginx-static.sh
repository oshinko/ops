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

if [ -z "$TARGET" ]; then
  echo '$TARGET is required'
  exit 1
fi

here=`dirname $0`

SERVER_ROOT=/usr/share/nginx-servers/$SERVER/$PORT

cat << EOF | ssh $KEYPAIR_OPTION $REMOTE sh
sudo mkdir -p $SERVER_ROOT
sudo chown -R \`whoami\` $SERVER_ROOT
EOF

scp -r $KEYPAIR_OPTION $TARGET $REMOTE:$SERVER_ROOT

cat $here/init/nginx-on-linux.sh \
  | ssh $KEYPAIR_OPTION $REMOTE \
    NGINX_SERVER_NAME=$SERVER \
    NGINX_PORT=$PORT \
    NGINX_SERVER_ROOT=$SERVER_ROOT \
    NGINX_BASIC_AUTH_USER=$USER \
    NGINX_BASIC_AUTH_PASS=$PASS \
    NGINX_TRY_FILES=$TRY_FILES \
    sh
