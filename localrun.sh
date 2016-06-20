#!/bin/bash
set -e
#set -x
cd $(dirname "$(readlink -f $0)")

git pull

do_akhet() {
    echo "Exec for "$1
    if test ! -d "$1"
    then
        echo " > Missing $1 => git clone..."
        git clone "https://github.com/AkhetLab/$1.git"
    else
        echo " > Found $1 => git pull..."
        cd "$1"
        git pull
        cd ..
    fi
    cd "$1"
    echo " > Build"
    ./localbuild.sh &> /dev/null
    cd ..
}

HOMEDIRS_PATH=$(pwd)/homedirs/
if test ! -d $HOMEDIRS_PATH
then
    mkdir $HOMEDIRS_PATH
fi

docker build -t akhetbase/example-ui example-ui/

if test ! -d AkhetRepos/
then
    mkdir AkhetRepos/
fi
cd AkhetRepos/

do_akhet akhet
do_akhet akhet-firewall

if test ! -c /dev/nvidia-uvm
then
    echo " > Standard akhet setup"
    do_akhet akhet-base-ubuntu-16-04
    do_akhet ubuntu-xterm
    AKHET_CUDA="off"
    AKHET_CUDA_DEVS=$(ls /dev/nvidia[0-9] | tr ' ' ',')
else
    echo " > Cuda akhet setup"
    do_akhet akhet-base-ubuntu-14-04-cuda-7-5
    do_akhet ubuntu-xterm-cuda
    AKHET_CUDA="on"
    AKHET_CUDA_DEVS=$(ls /dev/nvidia[0-9] | tr ' ' ',')
fi

if docker inspect akhet &> /dev/null
then
    docker stop  akhet || true
    docker rm    akhet
fi
if docker inspect akhet-example-ui &> /dev/null
then
    docker stop  akhet-example-ui || true
    docker rm    akhet-example-ui
fi
docker create \
 --name akhet \
 -ti \
 -p 8080:80  \
 -v /var/run/docker.sock:/var/run/docker.sock \
 akhetbase/akhet

TMP_AKHET_INI=`mktemp`

cat <<EOF > $TMP_AKHET_INI
[Akhet]
network_profiles=default
resource_profiles=default
storages=default
connection_method=socket
public_hostname=localhost
external_port=8080
external_ssl_port=8443
cuda=$AKHET_CUDA
cuda_devices=$AKHET_CUDA_DEVS
api_username=akhetdemouser
api_password=akhetdemopass
api_whitelist_ip=127.0.0.1,192.168.0.0/16,172.16.0.0/12,10.0.0.0/8


[network:default]
defaultrule=ACCEPT

[storage:default]
hostpath=$HOMEDIRS_PATH/{username}/
guestpath=/home/user/

[resource:default]
ram=1g
EOF
# cat $TMP_AKHET_INI
docker cp $TMP_AKHET_INI akhet:/etc/akhet.ini
rm -Rf $TMP_AKHET_INI_DIR

docker start akhet
docker run \
  --name akhet-example-ui \
 -tid \
 -p 80:80 \
 --link akhet:akhet \
 akhetbase/example-ui
