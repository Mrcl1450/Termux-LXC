#!/usr/bin/env sh

export XDG_RUNTIME_DIR=${TMPDIR}

kill -9 $(pgrep -f "termux.x11") 2>/dev/null

sudo chown $USER:$USER /data/data/com.termux/files/usr/tmp

pulseaudio --start \
    --load="module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1" \
    --exit-idle-time=-1

termux-x11 :0 -ac -extension MIT-SHM &

sudo mount -B "/data/data/com.termux/files/usr/var/lib/lxc/ubuntu/rootfs" "/data/data/com.termux/files/usr/var/lib/lxc/ubuntu/rootfs"
sudo mount -i -o remount,suid "/data/data/com.termux/files/usr/var/lib/lxc/ubuntu/rootfs"

exit 0
