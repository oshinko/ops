if [ -z "$NGINX_SERVER_NAME" ]; then
  NGINX_SERVER_NAME=_
fi

if [ -z "$NGINX_PORT" ]; then
  PORT=80
fi

if [ -z "$NGINX_SERVER_ROOT" ] && [ -z "$NGINX_UPSTREAM_SERVER" ]; then
  echo 'requires $NGINX_SERVER_ROOT or $NGINX_UPSTREAM_SERVER'
  exit 1
fi

if [ -z "$NGINX_TRY_FILES" ]; then
  NGINX_TRY_FILES='$uri/ $uri/index.html'
fi

NGINX_SERVER_ID=$NGINX_SERVER_NAME-$NGINX_PORT
NGINX_SERVER_META=/usr/share/nginx-server-meta/$NGINX_SERVER_ID

echo "Initial Parameters"
echo "  NGINX_PORT: $NGINX_PORT"
echo "  NGINX_SERVER_NAME: $NGINX_SERVER_NAME"
echo "  NGINX_SERVER_ID: $NGINX_SERVER_ID"
echo "  NGINX_SERVER_META: $NGINX_SERVER_META"
echo "  NGINX_SERVER_ROOT: $NGINX_SERVER_ROOT"
echo "  NGINX_UPSTREAM_SERVER: $NGINX_UPSTREAM_SERVER"
echo "  NGINX_BASIC_AUTH_USER: $NGINX_BASIC_AUTH_USER"
echo "  NGINX_BASIC_AUTH_PASS: $NGINX_BASIC_AUTH_PASS"
echo "  NGINX_TRY_FILES: $NGINX_TRY_FILES"
echo

sudo mkdir -p $NGINX_SERVER_META

# Nginx
sudo amazon-linux-extras install nginx1 -y

if [ -n "$NGINX_BASIC_AUTH_USER" ] && [ -n "$NGINX_BASIC_AUTH_PASS" ]; then
  sudo sh -c "cat << 'EOF' > $NGINX_SERVER_META/.htpasswd
$NGINX_BASIC_AUTH_USER:`openssl passwd -apr1 $NGINX_BASIC_AUTH_PASS`
EOF"
  BASIC_AUTH="auth_basic "Restricted";
auth_basic_user_file $NGINX_SERVER_META/.htpasswd;"
fi

if [ -n "$NGINX_SERVER_ROOT" ]; then
  sudo sh -c "cat << 'EOF' > /etc/nginx/conf.d/$NGINX_SERVER_ID.conf
server {
    listen       $NGINX_PORT;
    listen       [::]:$NGINX_PORT;
    server_name  $NGINX_SERVER_NAME;
    root $NGINX_SERVER_ROOT;

    $BASIC_AUTH

    # Load configuration files for the default server block.
    include /etc/nginx/default.d/*.conf;

    error_page 404 /404.html;
    location = /40x.html {
    }

    error_page 500 502 503 504 /50x.html;
    location = /50x.html {
    }

    try_files \$uri $NGINX_TRY_FILES =404;
}
EOF"
fi

if [ -n "$NGINX_UPSTREAM_SERVER" ]; then
  sudo sh -c "cat << 'EOF' > /etc/nginx/conf.d/$NGINX_SERVER_ID.conf
upstream $NGINX_SERVER_ID {
  server $NGINX_UPSTREAM_SERVER fail_timeout=0;
}
server {
  listen       $NGINX_PORT;
  listen       [::]:$NGINX_PORT;
  server_name  $NGINX_SERVER_NAME;

  $BASIC_AUTH

  # Load configuration files for the default server block.
  include /etc/nginx/default.d/*.conf;

  client_max_body_size 4G;

  keepalive_timeout 5;

  location / {
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto \$scheme;
    proxy_set_header Host \$http_host;
    proxy_redirect off;
    proxy_pass http://$NGINX_SERVER_ID;
  }
}
EOF"
fi

sudo systemctl enable nginx.service
sudo systemctl restart nginx.service
