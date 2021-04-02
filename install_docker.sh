# install docker
#
apt update
apt install apt-transport-https ca-certificates curl gnupg2 software-properties\
-common
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/debian $\
(lsb_release -cs) stable"
apt update
apt-cache policy docker-ce
apt install docker-ce
adduser production docker

# install docker compose
#
curl -L https://github.com/docker/compose/releases/download/1.25.3/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose

chmod +x /usr/local/bin/docker-compose

# install postgres 12
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc |  apt-key add -

echo "deb http://apt.postgresql.org/pub/repos/apt/ `lsb_release -cs`-pgdg main" |  tee  /etc/apt/sources.list.d/pgdg.list

apt update
apt -y install postgresql-client-12

# isntall let's encrypt stuff
apt install python3-acme python3-certbot python3-mock python3-openssl python3-pkg-resources python3-pyparsing python3-zope.interface

apt install python3-certbot-nginx
