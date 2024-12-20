#!/data/data/com.termux/files/usr/bin/env sh

#https://github.com/atamshkai/Phantom-Process-Killer

pkg update
pkg upgrade -y
pkg install -y root-repo
pkg install -y x11-repo
pkg install -y tur-repo
pkg install -y tsu nano mount-utils pulseaudio termux-tools iptables dnsmasq iproute2 wget termux-x11-nightly

sudo setenforce 0

termux-wake-lock

wget https://github.com/Mrcl1450/Test1/releases/download/lxc/lxc-lts_6.0.2_aarch64.deb
pkg install -y ./lxc-lts_6.0.2_aarch64.deb

#cgroupv1
#sudo mount -t tmpfs -o mode=755 tmpfs /sys/fs/cgroup && sudo mkdir -p /sys/fs/cgroup/devices && sudo mount -t cgroup -o devices cgroup /sys/fs/cgroup/devices && sudo mkdir -p /sys/fs/cgroup/systemd && sudo mount -t cgroup cgroup -o none,name=systemd /sys/fs/cgroup/systemd

#for cg in blkio cpu cpuacct cpuset devices freezer memory; do
#   if [ ! -d "/sys/fs/cgroup/${cg}" ]; then
#       sudo mkdir -p "/sys/fs/cgroup/${cg}"
#   fi

#   if ! sudo mountpoint -q "/sys/fs/cgroup/${cg}"; then
#       sudo mount -t cgroup -o "${cg}" cgroup "/sys/fs/cgroup/${cg}" || true
#   fi
#done

#echo "lxc.init.cmd = /sbin/init systemd.unified_cgroup_hierarchy=0" >> /$PREFIX/share/lxc/config/common.conf

#cgroupv2
#sudo mount -t cgroup2 none /sys/fs/cgroup
echo "lxc.init.cmd = /sbin/init systemd.unified_cgroup_hierarchy=1" >> /$PREFIX/share/lxc/config/common.conf

echo "lxc.cgroup.devices.allow = a *:* rwm" >> /$PREFIX/share/lxc/config/common.conf
echo "lxc.cgroup.devices.allow = c 10:200 rwm" >> /$PREFIX/share/lxc/config/common.conf

echo "features: mount=fuse,nesting=1,fuse=1" >> /$PREFIX/share/lxc/config/common.conf
echo "lxc.mount.entry = /dev/fuse dev/fuse none bind,optional,create=file" >> /$PREFIX/share/lxc/config/common.conf

echo "lxc.cap.drop =" >> /$PREFIX/share/lxc/config/common.conf
echo "lxc.cap.drop = mac_override sys_time sys_module sys_rawio" >> /$PREFIX/share/lxc/config/common.conf

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

echo "lxc.mount.entry = /dev/shm dev/shm none bind,optional,create=dir" >> /$PREFIX/share/lxc/config/common.conf
echo "lxc.mount.entry = /dev/tty dev/tty none bind,optional,create=file" >> /$PREFIX/share/lxc/config/common.conf

# Freedreno Turnip (Only available for Qualcomm Snapdragon)
echo "lxc.mount.entry = /dev/kgsl-3d0 dev/kgsl-3d0 none bind,optional,create=file" >> /$PREFIX/share/lxc/config/common.conf
echo "lxc.mount.entry = /dev/dri dev/dri none bind,optional,create=dir" >> /$PREFIX/share/lxc/config/common.conf
#echo "lxc.mount.entry = /dev/dma_heap dev/dma_heap none bind,optional,create=dir" >> /$PREFIX/share/lxc/config/common.conf
echo "lxc.mount.entry = /dev/ion dev/ion none bind,optional,create=dir" >> /$PREFIX/share/lxc/config/common.conf

echo "lxc.mount.entry = /var/log/journal var/log/journal none bind,optional,create=dir" >> /$PREFIX/share/lxc/config/common.conf

echo "lxc.hook.post-stop = /data/data/com.termux/files/home/Termux-LXC/post-stop.sh" >> /$PREFIX/share/lxc/config/common.conf

termux-x11 :0 -ac -extension MIT-SHM &

sudo lxc-create -t download -n ubuntu -- -d ubuntu -r oracular -a arm64

sudo mount -B "/data/data/com.termux/files/usr/var/lib/lxc/ubuntu/rootfs" "/data/data/com.termux/files/usr/var/lib/lxc/ubuntu/rootfs"
sudo mount -i -o remount,suid "/data/data/com.termux/files/usr/var/lib/lxc/ubuntu/rootfs"

CONTAINER="ubuntu"; sudo bash -c "mkdir '${PREFIX}/var/lib/lxc/${CONTAINER}/rootfs/tmp/.X11-unix' 2>/dev/null; umount '${PREFIX}/var/lib/lxc/${CONTAINER}/rootfs/tmp/.X11-unix' 2>/dev/null; mount --bind '${PREFIX}/tmp/.X11-unix' '${PREFIX}/var/lib/lxc/${CONTAINER}/rootfs/tmp/.X11-unix'"

unset LD_PRELOAD

sudo chmod +x /data/data/com.termux/files/home/Termux-LXC/post-stop.sh

sudo lxc-start -n ubuntu
sudo lxc-attach -n ubuntu /bin/passwd root

cat << 'EOF' > setup-lxc.sh
#!/bin/bash
# Backup the original udevadm binary
if [ ! -e /usr/bin/udevadm.original ]; then
  mv /usr/bin/udevadm /usr/bin/udevadm.original
fi

# Create the new udevadm wrapper
cat << 'WRAPPER' > /usr/bin/udevadm
#!/usr/bin/bash
/usr/bin/udevadm.original "\$@" || true
WRAPPER

# Set the correct permissions
chmod 755 /usr/bin/udevadm

chmod 644 /run/systemd/system/systemd-networkd-wait-online.service.d/10-netplan.conf
chmod 644 /run/systemd/system/netplan-ovs-cleanup.service

# Set nameserver
sudo rm -f /etc/resolv.conf
echo "nameserver 8.8.8.8" > /etc/resolv.conf
systemctl stop systemd-resolved
systemctl disable systemd-resolved

# Update and install necessary packages
apt update
apt install -y wget nano squashfuse fuse

apt-mark hold network-manager
apt install -y mate-desktop-environment-extras mate-terminal mate-tweak lightdm lightdm-gtk-greeter
apt install -y yaru-theme-gtk yaru-theme-icon ubuntu-wallpapers dconf-cli

apt install -y snapd
snap install snap-store

wget https://github.com/Mrcl1450/mesa-turnip/raw/main/build_deb_mesa.sh
bash build_deb_mesa.sh
rm build_deb_mesa.sh

apt install ./Desktop/mesa-vulkan-kgsl_*_arm64.deb

echo "MESA_LOADER_DRIVER_OVERRIDE=zink" >> /etc/environment
echo "VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/freedreno_icd.aarch64.json:/usr/share/vulkan/icd.d/freedreno_icd.armv7l.json" >> /etc/environment
echo "TU_DEBUG=noconform" >> /etc/environment

echo "PULSE_SERVER=127.0.0.1:4713" >> /etc/environment
echo "DISPLAY=:0" >> /etc/environment

adduser lxc
usermod -aG sudo lxc

#pulseaudio --start --load="module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1" --exit-idle-time=-1
#dbus-launch --exit-with-session mate-session &
EOF

sudo mv setup-lxc.sh /data/data/com.termux/files/usr/tmp/
#Doesn't work for now. Run inside container
#sudo lxc-attach -n ubuntu -- /usr/bin/bash /tmp/setup-lxc.sh

sudo lxc-stop -n ubuntu -k

sudo chmod +x ~/Termux-LXC/startubuntu
sudo mv ~/Termux-LXC/startubuntu /data/data/com.termux/files/usr/bin/

#sudo lxc-start -n ubuntu -d -F

#Reconnect Wifi if no internet
