#!/bin/bash
set -e

WORKDIR="$(mktemp -d)"
SERVERS=("8.8.8.8" "8.8.4.4")
# Not using best possible CDN pop: 1.2.4.8 210.2.4.8 223.5.5.5 223.6.6.6
# Dirty cache: 119.29.29.29 182.254.116.116

CONF_WITH_SERVERS=(accelerated-domains.china) # remove apple.china google.china
CONF_SIMPLE=(bogus-nxdomain.china)

echo "Downloading latest configurations..."
wget https://github.com/iYUYUE/dnsmasq-china-list/raw/master/accelerated-domains.china.conf -P "$WORKDIR"
wget https://github.com/iYUYUE/dnsmasq-china-list/raw/master/bogus-nxdomain.china.conf -P "$WORKDIR"

echo "Removing old configurations..."
for _conf in "${CONF_WITH_SERVERS[@]}" "${CONF_SIMPLE[@]}"; do
  rm -f /etc/dnsmasq.d/"$_conf"*.conf
done

echo "Installing new configurations..."
for _conf in "${CONF_SIMPLE[@]}"; do
  cp "$WORKDIR/$_conf.conf" "/etc/dnsmasq.d/$_conf.conf"
done

for _server in "${SERVERS[@]}"; do
  for _conf in "${CONF_WITH_SERVERS[@]}"; do
    cp "$WORKDIR/$_conf.conf" "/etc/dnsmasq.d/$_conf.$_server.conf"
  done

  sed -i "s|^\(server.*\)/[^/]*$|\1/$_server|" /etc/dnsmasq.d/*."$_server".conf
done

echo "Restarting dnsmasq service..."
if hash systemctl 2>/dev/null; then
  systemctl restart dnsmasq
elif hash service 2>/dev/null; then
  service dnsmasq restart
elif hash rc-service 2>/dev/null; then
  rc-service dnsmasq restart
else
  killall -HUP dnsmasq
fi

echo "Cleaning up..."
rm -r "$WORKDIR"
