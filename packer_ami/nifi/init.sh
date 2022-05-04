#!/bin/bash
set -euo pipefail

sleep 30

VERSION="1.16.1"
WORK_DIR="/opt/nifi/"
PROPERTIES_PATH=$WORK_DIR"nifi-"$VERSION"/conf/nifi.properties"
AUTHORIZER_PATH=$WORK_DIR"nifi-"$VERSION"/conf/authorizers.xml"

## install related packages
sudo apt update
sudo apt install net-tools
sudo apt install xmlstarlet
sudo apt install -y awscli 
sudo apt install -y openjdk-8-jdk

# Download nifi and nifi-toolkit packages
sudo mkdir -p $WORK_DIR && cd $WORK_DIR
sudo wget https://archive.apache.org/dist/nifi/$VERSION/nifi-$VERSION-bin.tar.gz
sudo wget https://archive.apache.org/dist/nifi/$VERSION/nifi-toolkit-$VERSION-bin.tar.gz
sudo tar zxvf nifi-$VERSION-bin.tar.gz
sudo tar zxvf nifi-toolkit-$VERSION-bin.tar.gz

# Generate self-signed certificate with nifi-toolkit
sudo ./nifi-toolkit-$VERSION/bin/tls-toolkit.sh standalone -n "localhost"
sudo cp ./localhost/* ./nifi-$VERSION/conf/

## Modify nifi.properties and setting https and oidc
sudo sed -i "/nifi.web.https.host=/ s/=.*/=/" $PROPERTIES_PATH
sudo sed -i "/nifi.web.proxy.host=/ s/=.*/=nifi-staging.whoscall.com/" $PROPERTIES_PATH
sudo sed -i "/nifi.security.user.oidc.discovery.url=/ s/=.*/=https:\/\/accounts.google.com\/.well-known\/openid-configuration/" $PROPERTIES_PATH
sudo sed -i "/nifi.security.user.oidc.client.id=/ s/=.*/="$GOOGLE_CLIENT_ID"/" $PROPERTIES_PATH
sudo sed -i "/nifi.security.user.oidc.client.secret=/ s/=.*/="$GOOGLE_CLIENT_SECRET"/" $PROPERTIES_PATH
sudo sed -i "/nifi.security.user.login.identity.provider=/ s/=.*/=/" $PROPERTIES_PATH
sudo sed -i "/nifi.security.user.authorizer=/ s/=.*/=managed-authorizer/" $PROPERTIES_PATH

## authorizer settings
sudo xmlstarlet ed --inplace -u "/authorizers/userGroupProvider/property[@name='Initial User Identity 1']" -v $ADMIN_GMAIL $AUTHORIZER_PATH
sudo xmlstarlet ed --inplace -u "/authorizers/accessPolicyProvider/property[@name='Initial Admin Identity']" -v $ADMIN_GMAIL $AUTHORIZER_PATH

## Setting service daemon in systemd
sudo mv /tmp/nifi.service /etc/systemd/system/nifi.service
sudo systemctl daemon-reload
sudo systemctl status nifi
