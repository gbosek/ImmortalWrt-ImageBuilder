#!/bin/bash
set -e

PROFILE="${PROFILE:-1024}"
ROUTER_IP="${ROUTER_IP:-192.168.10.222}"
GATEWAY_IP="${GATEWAY_IP:-192.168.10.1}"
DNS_IP="${DNS_IP:-192.168.10.1}"

echo "============================================"
echo " N100 ImmortalWrt 25.12.x bypass-router build"
echo " RootFS: ${PROFILE} MB"
echo " Router IP: ${ROUTER_IP}"
echo " Gateway: ${GATEWAY_IP}"
echo " DNS: ${DNS_IP}"
echo "============================================"

# Dedicated overlay: keep the upstream files untouched for other workflows.
N100_FILES="/tmp/n100-files"
rm -rf "${N100_FILES}"
mkdir -p "${N100_FILES}"
cp -a /home/build/immortalwrt/files/. "${N100_FILES}/"

# This script runs after upstream 99-custom.sh and converts the one-NIC VM
# into a fixed-IP bypass router.
mkdir -p "${N100_FILES}/etc/uci-defaults"
cat > "${N100_FILES}/etc/uci-defaults/99-n100-bypass.sh" <<EOF
#!/bin/sh

uci set system.@system[0].hostname='N100-ImmortalWrt'

uci set network.lan.proto='static'
uci set network.lan.ipaddr='${ROUTER_IP}'
uci set network.lan.netmask='255.255.255.0'
uci set network.lan.gateway='${GATEWAY_IP}'
uci -q delete network.lan.dns
uci add_list network.lan.dns='${DNS_IP}'
uci commit network

# Bypass router must not compete with the main router's DHCP/RA services.
uci set dhcp.lan.ignore='1'
uci set dhcp.lan.ra='disabled'
uci set dhcp.lan.dhcpv6='disabled'
uci set dhcp.lan.ndp='disabled'
uci commit dhcp

# Keep LAN forwarding open for gateway/transparent-proxy use.
uci -q set firewall.@zone[0].input='ACCEPT'
uci -q set firewall.@zone[0].output='ACCEPT'
uci -q set firewall.@zone[0].forward='ACCEPT'
uci commit firewall

exit 0
EOF
chmod +x "${N100_FILES}/etc/uci-defaults/99-n100-bypass.sh"

# Nikki APKs for OpenWrt 25.12 x86_64.
# Sparse clone keeps the download small while still following the maintained package set.
rm -rf /tmp/wukong-apk
git clone --depth=1 --filter=blob:none --sparse https://github.com/wukongdaily/apk.git /tmp/wukong-apk
git -C /tmp/wukong-apk sparse-checkout set run/x86/nikki
mkdir -p /home/build/immortalwrt/packages
find /tmp/wukong-apk/run/x86/nikki -maxdepth 1 -type f -name '*.apk' -exec cp -v {} /home/build/immortalwrt/packages/ \;

PACKAGES=""
# Full Chinese LuCI management experience
PACKAGES="$PACKAGES luci-i18n-base-zh-cn"
PACKAGES="$PACKAGES luci-i18n-firewall-zh-cn"
PACKAGES="$PACKAGES luci-i18n-package-manager-zh-cn"
PACKAGES="$PACKAGES luci-i18n-diskman-zh-cn"
PACKAGES="$PACKAGES luci-i18n-filemanager-zh-cn"
PACKAGES="$PACKAGES luci-i18n-ttyd-zh-cn"
PACKAGES="$PACKAGES luci-i18n-autoreboot-zh-cn"
PACKAGES="$PACKAGES luci-theme-argon luci-app-argon-config luci-i18n-argon-config-zh-cn"

# Web terminal / storage / everyday admin tools
PACKAGES="$PACKAGES ttyd luci-app-ttyd"
PACKAGES="$PACKAGES block-mount fdisk lsblk parted"
PACKAGES="$PACKAGES openssh-sftp-server"
PACKAGES="$PACKAGES bash curl ca-bundle ca-certificates ip-full unzip"
PACKAGES="$PACKAGES ethtool htop nano"

# Nikki + Mihomo transparent proxy.
# Dependencies such as mihomo/yq/kmod-nft-socket/kmod-dummy are resolved by apk.
PACKAGES="$PACKAGES nikki luci-app-nikki luci-i18n-nikki-zh-cn"

# OpenClash kernel ABI dependencies are baked into the firmware so OpenClash
# can be installed later without kernel-version mismatch.
PACKAGES="$PACKAGES kmod-tun kmod-inet-diag kmod-nft-tproxy kmod-nft-socket"
PACKAGES="$PACKAGES luci-compat"

# Intel i225/i226 driver (also useful if the NIC is later passed through to the VM).
PACKAGES="$PACKAGES kmod-igc"

echo "Building with packages:"
echo "${PACKAGES}"

make image \
  PROFILE="generic" \
  PACKAGES="${PACKAGES}" \
  FILES="${N100_FILES}" \
  ROOTFS_PARTSIZE="${PROFILE}"

echo "N100 image build completed."
