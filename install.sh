#!/data/data/com.termux/files/usr/bin/env sh

#https://github.com/atamshkai/Phantom-Process-Killer

pkg update
pkg upgrade -y
pkg install -y root-repo
pkg install -y x11-repo
pkg install -y tsu nano mount-utils pulseaudio termux-tools dos2unix iptables dnsmasq iproute2 wget termux-x11-nightly

termux-wake-lock

wget https://github.com/Mrcl1450/Test1/releases/download/lxc/lxc-lts_6.0.2_aarch64.deb

pkg install -y ./lxc-lts_6.0.2_aarch64.deb

sudo mount -t tmpfs -o mode=755 tmpfs /sys/fs/cgroup && sudo mkdir -p /sys/fs/cgroup/devices && sudo mount -t cgroup -o devices cgroup /sys/fs/cgroup/devices && sudo mkdir -p /sys/fs/cgroup/systemd && sudo mount -t cgroup cgroup -o none,name=systemd /sys/fs/cgroup/systemd

for cg in blkio cpu cpuacct cpuset devices freezer memory; do
   if [ ! -d "/sys/fs/cgroup/${cg}" ]; then
       sudo mkdir -p "/sys/fs/cgroup/${cg}"
   fi

   if ! sudo mountpoint -q "/sys/fs/cgroup/${cg}"; then
       sudo mount -t cgroup -o "${cg}" cgroup "/sys/fs/cgroup/${cg}" || true
   fi
done

#echo "lxc.init.cmd = /sbin/init systemd.unified_cgroup_hierarchy=0" >> /$PREFIX/share/lxc/config/common.conf
echo "lxc.cgroup.devices.allow = a *:* rwm" >> /$PREFIX/share/lxc/config/common.conf
echo "lxc.cgroup.devices.allow = c 10:200 rwm" >> /$PREFIX/share/lxc/config/common.conf
echo "lxc.mount.entry = /dev/fuse dev/fuse none bind,optional,create=file" >> /$PREFIX/share/lxc/config/common.conf

sed -i 's/lxc\.net\.0\.type = veth/lxc.net.0.type = none/g' /$PREFIX/etc/lxc/default.conf

echo "USE_LXC_BRIDGE=\"true\"" > /${PREFIX}/etc/default/lxc-net

sudo ${PREFIX}/libexec/lxc/lxc-net start

getway=$(ip -4 addr show wlan0 | awk '/inet/ {print $2}' | cut -d/ -f1)

sudo ip rule add pref 1 from all lookup main
sudo ip rule add pref 2 from all lookup default
sudo ip route add default via $getway dev wlan0
sudo ip rule add from all lookup main pref 30000

pulseaudio --start \
    --load="module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1" \
    --exit-idle-time=-1

# X11
echo "lxc.mount.entry = /data/data/com.termux/files/usr/tmp tmp none bind,optional,create=dir" >> /$PREFIX/share/lxc/config/common.conf
echo "lxc.mount.entry = /data/data/com.termux/files/usr/tmp/.X11-unix tmp/.X11-unix none bind,ro,optional,create=dir" >> /$PREFIX/share/lxc/config/common.conf

# Freedreno Turnip (Only available for Qualcomm Snapdragon)
echo "lxc.mount.entry = /dev/kgsl-3d0 dev/kgsl-3d0 none bind,optional,create=file" >> /$PREFIX/share/lxc/config/common.conf
echo "lxc.mount.entry = /dev/dri dev/dri none bind,optional,create=dir" >> /$PREFIX/share/lxc/config/common.conf
echo "lxc.mount.entry = /dev/dma_heap dev/dma_heap none bind,optional,create=dir" >> /$PREFIX/share/lxc/config/common.conf

sudo lxc-create -t download -n ubuntu -- -d ubuntu -r noble -a arm64
sudo lxc-start -n ubuntu
sudo lxc-attach -n ubuntu /bin/passwd root
sudo lxc-attach -n ubuntu /bin/login































