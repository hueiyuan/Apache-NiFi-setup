#!/bin/bash
set -euo pipefail

sleep 30

VERSION="1.16.1"
WORK_DIR="/opt/nifi-registry/"
PROPERTIES_PATH=$WORK_DIR"nifi-registry-"$VERSION"/conf/nifi-registry.properties"
AUTHORIZER_PATH=$WORK_DIR"nifi-registry-"$VERSION"/conf/authorizers.xml"
TLS_PROPERTIES_PATH=$WORK_DIR"localhost/nifi.properties"

function getProperty {
   PROP_KEY=$1
   PROP_VALUE=`sudo cat $TLS_PROPERTIES_PATH | grep "$PROP_KEY" | cut -d'=' -f2`
   echo $PROP_VALUE
}

## install related packages
sudo apt-get update
sudo apt-get install net-tools
sudo apt-get install xmlstarlet
sudo apt-get install -y awscli 
sudo apt-get install -y openjdk-8-jdk
echo "[INFO] Installed required packages."

## Download nifi-regsitry and nifi-toolkit packages
sudo mkdir -p $WORK_DIR && cd $WORK_DIR
sudo wget https://archive.apache.org/dist/nifi/$VERSION/nifi-registry-$VERSION-bin.tar.gz
sudo wget https://archive.apache.org/dist/nifi/$VERSION/nifi-toolkit-$VERSION-bin.tar.gz
sudo wget https://jdbc.postgresql.org/download/postgresql-42.3.3.jar
sudo tar zxvf nifi-registry-$VERSION-bin.tar.gz
sudo tar zxvf nifi-toolkit-$VERSION-bin.tar.gz
echo "[INFO] Download and uncompress nifi registry and nifi toolkit package."

## Generate self-signed certificate with nifi-toolkit
sudo $WORK_DIR"nifi-toolkit-"$VERSION"/bin/tls-toolkit.sh" standalone -n "localhost"
sudo su -c "cp $WORK_DIR"localhost/*.jks" $WORK_DIR"nifi-registry-"$VERSION"/conf/""
echo "[INFO] Generate keystore.jks and truststore.jks successfully!"

## Modify nifi.properties and setting https and oidc
sudo sed -i "/nifi.registry.web.http.port=/ s#=.*#=#" $PROPERTIES_PATH
sudo sed -i "/nifi.registry.web.https.port=/ s#=.*#=18443#" $PROPERTIES_PATH
sudo sed -i "/nifi.registry.security.needClientAuth=/ s#=.*#=false#" $PROPERTIES_PATH
echo "[INFO] Update nifi registry from http to https and clientauth successfully!"

##### keystore
sudo sed -i "/nifi.registry.security.keystore=/ s#=.*#=.\/conf\/keystore.jks#" $PROPERTIES_PATH
sudo sed -i "/nifi.registry.security.keystoreType=/ s#=.*#=jks#" $PROPERTIES_PATH
sudo sed -i "/nifi.registry.security.keystorePasswd=/ s#=.*#=$(getProperty "nifi.security.keystorePasswd")#" $PROPERTIES_PATH
sudo sed -i "/nifi.registry.security.keyPasswd=/ s#=.*#=$(getProperty "nifi.security.keyPasswd")#" $PROPERTIES_PATH
sudo sed -i "/nifi.registry.security.truststore=/ s#=.*#=.\/conf\/truststore.jks#" $PROPERTIES_PATH
sudo sed -i "/nifi.registry.security.truststoreType=/ s#=.*#=jks#" $PROPERTIES_PATH
sudo sed -i "/nifi.registry.security.truststorePasswd=/ s#=.*#=$(getProperty "nifi.security.truststorePasswd")#" $PROPERTIES_PATH
echo "[INFO] Update keystore and truststore for nifi registry successfully!"

### google oidc
sudo sed -i "/nifi.security.user.oidc.discovery.url=/ s#=.*#=https:\/\/accounts.google.com\/.well-known\/openid-configuration#" $PROPERTIES_PATH
sudo sed -i "/nifi.security.user.oidc.client.id=/ s#=.*#="$GOOGLE_CLIENT_ID"#" $PROPERTIES_PATH
sudo sed -i "/nifi.security.user.oidc.client.secret=/ s#=.*#="$GOOGLE_CLIENT_SECRET"#" $PROPERTIES_PATH
sudo sed -i "/nifi.registry.security.user.oidc.connect.timeout=/ s#=.*#=5 secs#" $PROPERTIES_PATH
sudo sed -i "/nifi.registry.security.user.oidc.read.timeout=/ s#=.*#=5 secs#" $PROPERTIES_PATH
echo "[INFO] Update google oauth openid settings for nifi registry successfully!"

### metadata db
# sudo sed -i "/nifi.registry.db.url=/ s#=.*#=jdbc:postgresql:\/\/localhost:5432\/nifi_registry#" $PROPERTIES_PATH
# sudo sed -i "/nifi.registry.db.driver.class=/ s#=.*#=org.postgresql.Driver#" $PROPERTIES_PATH
# sudo sed -i "/nifi.registry.db.driver.directory=/ s#=.*#=/home/ubuntu/nifi-registry/postgresql-42.3.3.jar#" $PROPERTIES_PATH
# sudo sed -i "/nifi.registry.db.username=/ s#=.*#="$DB_USERNAME"#" $PROPERTIES_PATH
# sudo sed -i "/nifi.registry.db.password=/ s#=.*#="$DB_PASSWORD"#" $PROPERTIES_PATH

## authorizer## authorizer settings
sudo xmlstarlet ed --inplace -u "/authorizers/userGroupProvider/property[@name='Initial User Identity 1']" -v $ADMIN_GMAIL $AUTHORIZER_PATH
sudo xmlstarlet ed --inplace -u "/authorizers/accessPolicyProvider/property[@name='Initial Admin Identity']" -v $ADMIN_GMAIL $AUTHORIZER_PATH
echo "[INFO] Update admin account for nifi registry successfully!"

## Setting service daemon in systemd/localhost/*.jks
sudo mv /tmp/nifi_registry.service /etc/systemd/system/nifi_registry.service
sudo systemctl daemon-reload
echo "[INFO] Setting and reload nifi registry systemd daemon successfully!"
