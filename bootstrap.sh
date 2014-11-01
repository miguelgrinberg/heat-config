#!/bin/bash
PROJECT=https://github.com/miguelgrinberg/heat-config
BRANCH=master

apt-get update
apt-get install -y python-pip python-dev python-lxml
pip install os-collect-config os-refresh-config os-apply-config dib-utils

wget $PROJECT/archive/$BRANCH.tar.gz
tar xzf $BRANCH.tar.gz
cd heat-config-$BRANCH/config
for DIR in *; do
    for FILE in `find $DIR -type f`; do
        mkdir -p `dirname /$FILE`
        cp $FILE /$FILE
    done
done
cd ../..

service os-collect-config start
