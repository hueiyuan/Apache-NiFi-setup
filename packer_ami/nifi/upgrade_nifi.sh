#!/bin/bash
set -euo pipefail

WORK_DIR="/opt/nifi/"
SYSTEMD_FILE="/etc/systemd/system/nifi.service"

help_and_exit() {
    echo "usage:       <path-to-script> migrate <original-nifi-version> <new-nifi-version>"
    echo "             <path-to-script> remove <original-nifi-version>"
    exit 1
}

if [ "$#" -lt 1 ]; then
    help_and_exit
fi

migrate_to_new_nifi() {
    old_nifi_dir=$WORK_DIR"nifi-"$OLD_NIFI_VERSION
    old_nifi_conf_dir=$old_nifi_dir"/conf"

    new_nifi_dir=$WORK_DIR"nifi-"$NEW_NIFI_VERSION
    new_nifi_conf_dir=$new_nifi_dir"/conf"

    cd $WORK_DIR
    sudo wget "https://archive.apache.org/dist/nifi/"$NEW_NIFI_VERSION"/nifi-"$NEW_NIFI_VERSION"-bin.tar.gz"
    sudo tar zxvf "nifi-"$NEW_NIFI_VERSION"-bin.tar.gz"
    sudo rm "nifi-"$NEW_NIFI_VERSION"-bin.tar.gz"
    echo "[INFO] Downloaded and uncompressed the newest nifi tar.gz!"
    
    cd $old_nifi_dir"/conf"
    sudo cp $old_nifi_conf_dir"/nifi.properties" $new_nifi_conf_dir
    sudo cp $old_nifi_conf_dir"/authorizers.xml" $new_nifi_conf_dir
    sudo cp $old_nifi_conf_dir"/authorizations.xml" $new_nifi_conf_dir
    sudo cp $old_nifi_conf_dir"/login-identity-providers.xml" $new_nifi_conf_dir
    sudo cp $old_nifi_conf_dir"/state-management.xml" $new_nifi_conf_dir
    sudo cp $old_nifi_conf_dir"/users.xml" $new_nifi_conf_dir
    sudo cp $old_nifi_conf_dir"/keystore.jks" $new_nifi_conf_dir
    sudo cp $old_nifi_conf_dir"/truststore.jks" $new_nifi_conf_dir
    echo "[INFO] Copied properties and xml files to the newest nifi folder!"
    
    sudo mkdir -p $new_nifi_conf_dir"/archive"
    sudo cp $old_nifi_conf_dir"/flow.json.gz" $new_nifi_conf_dir
    sudo cp $old_nifi_conf_dir"/flow.xml.gz" $new_nifi_conf_dir
    sudo rsync -a $new_nifi_conf_dir"/archive" $new_nifi_conf_dir
    echo "[INFO] Copied flow.json.gz and flow.xml.gz to the newest nifi folder!"

    sudo mkdir -p $new_nifi_dir"/state"
    sudo cp -r $old_nifi_dir"/state/" $new_nifi_dir"/state"
    echo "[INFO] Copied state folder to the newest nifi folder!"

    sudo sed -i "/ExecStart=/ s#=.*#=/opt/nifi/nifi-"$NEW_NIFI_VERSION"/bin/nifi.sh start#" $SYSTEMD_FILE
    sudo sed -i "/ExecStop=/ s#=.*#=/opt/nifi/nifi-"$NEW_NIFI_VERSION"/bin/nifi.sh start#" $SYSTEMD_FILE
    sudo sed -i "/ExecReload=/ s#=.*#=/opt/nifi/nifi-"$NEW_NIFI_VERSION"/bin/nifi.sh start#" $SYSTEMD_FILE
    echo "[INFO] Modified nifi.service service for new version nifi!"

    cd $WORK_DIR
    sudo systemctl daemon-reload
    sudo systemctl start nifi.service
    echo "[INFO] Start the new nifi service!"
} 

# Entries
case "$1" in
migrate)
    if [ "$#" -lt 3 ]; then
        help_and_exit
    fi

    OLD_NIFI_VERSION="$2"
    NEW_NIFI_VERSION="$3"
    shift 2

    sudo systemctl stop nifi.service
    echo "[INFO] Stopped nifi service."

    migrate_to_new_nifi $OLD_NIFI_VERSION $NEW_NIFI_VERSION
    echo "[INFO] Migrate to new version nifi service successfully."
    ;;

remove)
    if [ "$#" -lt 2 ]; then
        help_and_exit
    fi

    REMOVE_NIFI_VERSION="$2"
    shift 2

    sudo rm -rf $WORK_DIR"nifi-"$REMOVE_NIFI_VERSION
    echo "[INFO] Removed older nifi service folder."
    ;;
*)
    echo "unknown command: $1"
    exit 1
    ;;

esac

exit 0
