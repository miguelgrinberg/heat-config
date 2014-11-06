#!/bin/bash
REPO=https://github.com/miguelgrinberg/heat-config
BRANCH=master

while [[ $# > 0 ]]; do
    OPT="$1"
    shift

    case $OPT in
        -r|--repo)
            REPO="$1"
            shift
            ;;
        -b|--branch)
            BRANCH="$1"
            shift
            ;;
        *)
            echo "Unknown option $OPT"
            echo "Usage: $0 [OPTIONS]"
            echo "Options:"
            echo "  --repo|-r    source git repository (default \"$REPO\")"
            echo "  --branch|-b  git branch to install from (default \"$BRANCH\")"
            exit 1
            ;;
    esac
done

if [[ -e /usr/bin/yum  ]]; then
    yum install -y gcc-c++ python-pip python-devel python-lxml
elif [[ -e /usr/bin/apt-get ]]; then
    apt-get update
    apt-get install -y build-essential python-pip python-dev python-lxml
else
    echo Unsupported OS, try Ubuntu, Fedora or similar.
    exit 1
fi

pip install heat-cfntools os-collect-config os-refresh-config os-apply-config dib-utils

cd /root
curl -LO $REPO/archive/$BRANCH.tar.gz
tar xzf $BRANCH.tar.gz
cd heat-config-$BRANCH/config
for DIR in *; do
    for FILE in `find $DIR -type f`; do
        mkdir -p `dirname /$FILE`
        cp $FILE /$FILE
    done
done
cd ../..

if [[ -d /etc/init ]]; then
    cat >/etc/init/os-collect-config.conf <<EOF
start on runlevel [2345]
stop on runlevel [016]
respawn

# We're logging to syslog
console none

exec os-collect-config  2>&1 | logger -t os-collect-config
EOF
    service os-collect-config start
elif [[ -d /lib/systemd/system ]]; then
    cat >/lib/systemd/system/os-collect-config.service <<EOF
[Unit]
Description=Collect metadata and run hook commands.
After=syslog.target
After=network.target

[Service]
ExecStart=/usr/bin/os-collect-config
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
    systemctl enable os-collect-config
    systemctl start os-collect-config
else
    echo Only upstart and systemd are supported.
    exit 1
fi
