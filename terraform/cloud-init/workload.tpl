#!/bin/bash
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

echo "Updating package list"
apt-get update

echo "Installing prerequisites"
apt-get install -y ca-certificates curl gnupg lsb-release

echo "Adding Docker GPG key"
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

echo "Adding Docker repository"
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

echo "Updating package list with Docker repo"
apt-get update

echo "Installing Docker"
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

systemctl start docker
systemctl enable docker

#Wait for Internet access through the FGT by testing the docker registry
echo "Waiting for docker registry to be reachable"
curl --retry 20 -s -o /dev/null "https://index.docker.io/v2/"

echo "Installing containers"

# Demo Web App (Bank) - Port 2000
retries=5
until docker run -d --restart unless-stopped --name demo-web-app -p 2000:80 -e HOST_MACHINE_NAME="$(hostname)" benoitbmtl/demo-web-app
do
    docker pull benoitbmtl/demo-web-app
    sleep 2
    retries=$((retries - 1))
    if [ $retries -eq 0 ]; then
        echo "Failed to start demo-web-app after 5 retries"
        break
    fi
done

# OWASP Juice Shop - Port 3000
retries=5
until docker run -d --restart unless-stopped --name juice-shop -p 3000:3000 bkimminich/juice-shop
do
    docker pull bkimminich/juice-shop
    sleep 2
    retries=$((retries - 1))
    if [ $retries -eq 0 ]; then
        echo "Failed to start juice-shop after 5 retries"
        break
    fi
done

# Swagger Petstore - Port 4000
retries=5
until docker run -d --restart unless-stopped --name petstore3 -p 4000:8080 swaggerapi/petstore3
do
    docker pull swaggerapi/petstore3
    sleep 2
    retries=$((retries - 1))
    if [ $retries -eq 0 ]; then
        echo "Failed to start petstore3 after 5 retries"
        break
    fi
done

# DVWA with MariaDB - Port 1000
cat << 'EOF' > /root/compose.yml
volumes:
  dvwa:
services:
  dvwa:
    image: ghcr.io/digininja/dvwa:latest
    pull_policy: always
    environment:
      - DB_SERVER=db
    depends_on:
      - db
    ports:
      - 1000:80
    restart: always
  db:
    image: docker.io/library/mariadb:10
    environment:
      - MYSQL_ROOT_PASSWORD=dvwa
      - MYSQL_DATABASE=dvwa
      - MYSQL_USER=dvwa
      - MYSQL_PASSWORD=p@ssw0rd
    volumes:
      - dvwa:/var/lib/mysql
    restart: unless-stopped
EOF

docker compose -f /root/compose.yml up -d

echo "All containers started successfully"
echo "- Demo Web App (Bank): http://$(hostname -I | awk '{print $1}'):2000"
echo "- OWASP Juice Shop: http://$(hostname -I | awk '{print $1}'):3000"
echo "- Swagger Petstore: http://$(hostname -I | awk '{print $1}'):4000"
echo "- DVWA: http://$(hostname -I | awk '{print $1}'):1000"
