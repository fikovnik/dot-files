#!/bin/sh

name=transmission
country="cz"

# TODO: refactor to some docker utils
function rm_stopped {
	local name=$1
	local state
	state=$(status "$name")

	if [[ "$state" == "false" ]]; then
		docker rm "$name"
	fi
}

function status {
    local name="$1"
    docker inspect -f "{{.State.Running}}" "$name" || echo "false"
}

function start {
    local password=$(pass show internet/nordvpn.com | head -1)
    local username=$(pass show internet/nordvpn.com | tail -1 | sed 's/username: //g')

    docker run --cap-add=NET_ADMIN --device=/dev/net/tun -d \
           -v $HOME/NoBackup/transmission/:/data \
           -v /etc/localtime:/etc/localtime:ro \
           -e "OPENVPN_PROVIDER=NORDVPN" \
           -e "OPENVPN_USERNAME=$username" \
           -e "OPENVPN_PASSWORD=$password" \
           -e "PUID=$(id -u)" \
           -e "PGID=$(id -g)" \
           --dns 8.8.8.8 \
           --dns 8.8.4.4 \
           --log-driver json-file \
           --log-opt max-size=10m \
           --name "$name" \
           -p 9091:9091 \
           haugene/transmission-openvpn
}

case "$1" in
    start)
        rm_stopped "$name"
        start
        ;;
    stop)
        docker stop "$name"
        ;;
    restart)
        stop
        start
        ;;
    status)
        status "$name"
        ;;
    *)
        echo "Usage: $0 <start|stop|restart|status>"
        ;;
esac
