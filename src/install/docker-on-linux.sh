set -e

. /etc/os-release

install_compose_plugin_manually() {
  # https://docs.docker.com/compose/install/linux/#install-the-plugin-manually
  ARCH=`uname -m`
  DOCKER_CONFIG=${DOCKER_CONFIG:-/usr/local/lib/docker}
  mkdir -p $DOCKER_CONFIG/cli-plugins
  curl -SL https://github.com/docker/compose/releases/download/v2.20.3/docker-compose-linux-$ARCH \
       -o $DOCKER_CONFIG/cli-plugins/docker-compose
  chmod +x $DOCKER_CONFIG/cli-plugins/docker-compose
}

# ref: https://docs.docker.com/compose/install/linux/
if type apt > /dev/null 2>&1; then
  apt update
  apt install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release
  mkdir -p /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/$ID/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/$ID \
    $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
  apt update
  apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
  service docker start
  apt-cache madison docker-ce

elif type dnf > /dev/null 2>&1; then
  dnf install docker -y
  systemctl enable --now docker
  install_compose_plugin_manually

elif type yum > /dev/null 2>&1; then
  yum update -y

  if [ "$ID" = "amzn" ]; then
    yum install -y docker
  else
    yum install -y yum-utils
    yum-config-manager \
      --add-repo \
      https://download.docker.com/linux/$ID/docker-ce.repo
    yum install -y docker-ce docker-ce-cli containerd.io
  fi

  systemctl enable --now docker

  install_compose_plugin_manually
fi
