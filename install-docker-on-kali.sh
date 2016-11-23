# This script installs docker on the latest Kali Linux (or any Wheezy Debian distro)
echo "deb http://http.debian.net/debian wheezy-backports main" >> /etc/apt/sources.list.d/backports.list
/usr/bin/apt-get update
DEBIAN_FRONTEND=noninteractive /usr/bin/apt-get purge -y -qq "lxc-docker*"
DEBIAN_FRONTEND=noninteractive /usr/bin/apt-get purge -y -qq "docker.io*"
DEBIAN_FRONTEND=noninteractive /usr/bin/apt-get install -y -q apt-transport-https ca-certificates
apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
echo "deb https://apt.dockerproject.org/repo debian-wheezy main" > /etc/apt/sources.list.d/docker.list
/usr/bin/apt-get update
DEBIAN_FRONTEND=noninteractive /usr/bin/apt-get install -y -q docker-engine
service docker start
