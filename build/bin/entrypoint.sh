#!/usr/bin/env bash
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
##@Version       : 202112111512-git
# @Author        : Jason Hempstead
# @Contact       : jason@casjaysdev.com
# @License       : WTFPL
# @ReadME        : entrypoint.sh --help
# @Copyright     : Copyright: (c) 2021 Jason Hempstead, Casjays Developments
# @Created       : Saturday, Dec 11, 2021 15:12 EST
# @File          : entrypoint.sh
# @Description   :
# @TODO          :
# @Other         :
# @Resource      :
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
APPNAME="$(basename "$0" 2>/dev/null)"
VERSION="202112111512-git"
USER="${SUDO_USER:-${USER}}"
HOME="${USER_HOME:-${HOME}}"
SRC_DIR="${BASH_SOURCE%/*}"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Set bash options
if [[ "$1" == "--debug" ]]; then shift 1 && set -xo pipefail && export SCRIPT_OPTS="--debug" && export _DEBUG="on"; fi

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -'
# Set functions
__help() {
  echo 'docker entry point script
    options are:
'$APPNAME' --help
'$APPNAME' --version
'$APPNAME' --shell
'$APPNAME' --help
'$APPNAME' --health
'$APPNAME' --status
'
}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
__list_options() { echo "${1:-$ARRAY}" | sed 's|:||g;s|'$2'| '$3'|g' 2>/dev/null; }
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Additional functions
__run_dns() {
  named-checkconf -z /etc/named.conf
  named -c /etc/named.conf
}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Check for needed applications
type -P bash &>/dev/null || { echo "Missing: bash" && exit 1; }
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Set variables
exitCode=0

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Application Folders

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Show warn message if variables are missing

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Set options
SETARGS="$*"
SHORTOPTS=""
LONGOPTS="options,version,help,shell,health,status"
ARRAY=""
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Setup application options
setopts=$(getopt -o "$SHORTOPTS" --long "$LONGOPTS" -a -n "$APPNAME" -- "$@" 2>/dev/null)
eval set -- "${setopts[@]}" 2>/dev/null
while :; do
  case $1 in
  --options)
    shift 1
    [ -n "$1" ] || printf 'Current options for %s\n' "${PROG:-$APPNAME}"
    [ -z "$SHORTOPTS" ] || __list_options "Short Options" "-$SHORTOPTS" ',' '-'
    [ -z "$LONGOPTS" ] || __list_options "Long Options" "--$LONGOPTS" ',' '--'
    [ -z "$ARRAY" ] || __list_options "Base Options" "$ARRAY" ',' ''
    exit $?
    ;;
  --help)
    shift 1
    __help
    exit
    ;;
  --version)
    shift 1
    printf "$APPNAME Version: $VERSION\n"
    exit
    ;;
  --shell)
    shift 1
    bash -s /root/.profile -l
    exit $?
    ;;
  --health)
    shift 1
    exitCode=0
    for proc in named tor tftp named dhcp radvd php; do
      ps aux | grep -Ev 'grep|tail' | grep -q "$proc" && echo "$proc" || exitCode+=1
    done
    exit ${exitCode:-$?}
    ;;
  --status)
    shift 1
    netstat -taupln | grep -E '^udp|LISTEN'
    exit ${exitCode:-$?}
    ;;
  --)
    shift 1
    ARGS="$1"
    set --
    break
    ;;
  esac
done
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
[[ -f "/run/ddns.pid" ]] && echo "PID file exists" && exit 1
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Additional variables
[[ -f "/root/.bashrc" ]] || printf "source /etc/profile\ncd %s\n" "$HOME" >"/root/.bashrc"
[[ -f "/root/.bashrc" ]] && source "/root/.bashrc"
[[ -f "/config/env" ]] && source "/config/env"
DATE="$(date +%Y%m%d)01"
OLD_DATE="${OLD_DATE:-2018020901}"
NETDEV="$(ip route 2>/dev/null | grep default | sed -e "s/^.*dev.//" -e "s/.proto.*//" | awk '{print $1}')"
IPV4_ADDR="$(ifconfig $NETDEV 2>/dev/null | grep -E "venet|inet" | grep -v "127.0.0." | grep 'inet' | grep -v inet6 | awk '{print $2}' | sed s/addr://g | head -n1 | grep '^' || echo '')"
IPV6_ADDR="$(ifconfig "$NETDEV" 2>/dev/null | grep -E "venet|inet" | grep 'inet6' | grep -i global | awk '{print $2}' | head -n1 | grep '^' || echo '')"
IPV4_ADDR_GATEWAY="$(ip route show default | awk '/default/ {print $3}' | head -n1 | grep '^' || echo '')"
IPV4_ADDR="${IPV4_ADDR:-10.0.0.2}"
IPV4_ADDR_SUBNET="${IPV4_ADDR_SUBNET:-10.0.0.0}"
IPV4_ADDR_START="${IPV4_ADDR_START:-10.0.100.1}"
IPV4_ADDR_END="${IPV4_ADDR_END:-10.0.100.254}"
IPV4_ADDR_NETMASK="${IPV4_ADDR_NETMASK:-255.255.0.0}"
IPV4_ADDR_GATEWAY="${IPV4_ADDR_GATEWAY:-10.0.0.1}"
IPV6_ADDR="${IP6_ADDR:-2001:0db8:edfa:1234::2}"
IPV6_ADDR_SUBNET="${IPV6_ADDR_SUBNET:-2001:0db8:edfa:1234::}"
IPV6_ADDR_START="${IPV6_ADDR_START:-2001:0db8:edfa:1234:5678::1}"
IPV6_ADDR_END="${IPV6_ADDR_END:-2001:0db8:edfa:1234:5678::ffff}"
IPV6_ADDR_NETMASK="${IPV6_ADDR_NETMASK:-64}"
IPV6_ADDR_GATEWAY="${IPV6_ADDR_GATEWAY:-2001:0db8:edfa:1234::1}"

DOMAIN_NAME="${DOMAIN_NAME:-test}"
HOSTNAME="$(hostname -s).${DOMAIN_NAME}"
[[ "$DOMAIN_NAME" == "local" ]] && DOMAIN_NAME="test"
###############################################################################
[[ -f "/config/env" ]] && source "/config/env"
{
  echo 'Starting dynamic DNS server...'
  touch /run/ddns.pid
  date '+%Y-%m-%d %H:%M'
  echo "Setting hostname to $HOSTNAME"
} &>>/data/log/entrypoint.log
[[ -d "/data/log" ]] && rm -Rf /data/log/* || mkdir -p "/data/log"
[[ -f "/etc/profile" ]] && [[ ! -f "/root/.profile" ]] && cp -Rf "/etc/profile" "/root/.profile"

if [[ -f "/config/rndc.key" ]]; then
  RNDC_KEY="$(cat /config/rndc.key | grep secret | awk '{print $2}' | sed 's|;||g;s|"||g')"
else
  rndc-confgen -a -c /etc/rndc.key &>>/data/log/named.log
  RNDC_KEY="$(cat /etc/rndc.key | grep secret | awk '{print $2}' | sed 's|;||g;s|"||g')"
  [[ -f "/config/rndc.key" ]] || cp -Rf "/etc/rndc.key" "/config/rndc.key" &>>/data/log/entrypoint.log
  [[ -f "/config/rndc.conf" ]] || { [[ -f "/etc/rndc.conf" ]] && cp -Rf "/etc/rndc.conf" "/config/rndc.conf" &>>/data/log/entrypoint.log; }
fi
[[ -d "/etc/dhcp" ]] || mkdir -p "/etc/dhcp" &>>/data/log/entrypoint.log
[[ -d "/run/dhcp" ]] || mkdir -p "/run/dhcp" &>>/data/log/entrypoint.log
[[ -d "/var/tftpboot" ]] && [[ ! -d "/data/tftp" ]] && mv -f "/var/tftpboot" "/data/tftp" &>>/data/log/entrypoint.log
[[ -d "/var/lib/dhcp" ]] || mkdir -p "/var/lib/dhcp" &>>/data/log/entrypoint.log
[[ -d "/data/tor" ]] || cp -Rf "/var/lib/tor" "/data/tor" &>>/data/log/entrypoint.log
[[ -d "/data/web" ]] || cp -Rf "/var/lib/ddns/data/web" "/data/web" &>>/data/log/entrypoint.log
[[ -d "/data/named" ]] || cp -Rf "/var/lib/ddns/data/named" "/data/named" &>>/data/log/entrypoint.log
[[ -d "/config/tor" ]] || cp -Rf "/var/lib/ddns/config/tor" "/config/tor" &>>/data/log/entrypoint.log
[[ -d "/config/dhcp" ]] || cp -Rf "/var/lib/ddns/config/dhcp" "/config/dhcp" &>>/data/log/entrypoint.log
[[ -d "/config/named" ]] || cp -Rf "/var/lib/ddns/config/named" "/config/named" &>>/data/log/entrypoint.log
[[ -f "/config/radvd.conf" ]] || cp -Rf "/var/lib/ddns/config/radvd.conf" "/config/radvd.conf" &>>/data/log/entrypoint.log
[[ -f "/config/named.conf" ]] || cp -Rf "/var/lib/ddns/config/named.conf" "/config/named.conf" &>>/data/log/entrypoint.log
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Main application
find "/config" "/data" -type f -exec sed -i 's|'${OLD_DATE:-2018020901}'|'$DATE'|g' {} \;
find "/config" "/data" -type f -exec sed -i 's|REPLACE_DOMAIN|'$DOMAIN_NAME'|g' {} \;
find "/config" "/data" -type f -exec sed -i 's|REPLACE_WITH_RNDC_KEY|'$RNDC_KEY'|g' {} \;
find "/config" "/data" -type f -exec sed -i 's|REPLACE_IPV4_ADDRESS|'$IPV4_ADDR'|g' {} \;
find "/config" "/data" -type f -exec sed -i 's|REPLACE_IPV4_ADDR_START|'$IPV4_ADDR_START'|g' {} \;
find "/config" "/data" -type f -exec sed -i 's|REPLACE_IPV4_ADDR_END|'$IPV4_ADDR_END'|g' {} \;
find "/config" "/data" -type f -exec sed -i 's|REPLACE_IPV4_SUBNET|'$REPLACE_IPV4_ADDR_SUBNET'|g' {} \;
find "/config" "/data" -type f -exec sed -i 's|REPLACE_IPV4_NETMASK|'$IPV4_ADDR_NETMASK'|g' {} \;
find "/config" "/data" -type f -exec sed -i 's|REPLACE_IPV4_GATEWAY|'$IPV4_ADDR_GATEWAY'|g' {} \;
find "/config" "/data" -type f -exec sed -i 's|REPLACE_IPV6_ADDRESS|'$IPV6_ADDR'|g' {} \;
find "/config" "/data" -type f -exec sed -i 's|REPLACE_IPV6_ADDR_START|'$IPV6_ADDR_START'|g' {} \;
find "/config" "/data" -type f -exec sed -i 's|REPLACE_IPV6_ADDR_END|'$IPV6_ADDR_END'|g' {} \;
find "/config" "/data" -type f -exec sed -i 's|REPLACE_IPV6_SUBNET|'$REPLACE_IPV6_ADDR_SUBNET'|g' {} \;
find "/config" "/data" -type f -exec sed -i 's|REPLACE_IPV6_NETMASK|'$IPV6_ADDR_NETMASK'|g' {} \;
find "/config" "/data" -type f -exec sed -i 's|REPLACE_IPV6_GATEWAY|'$IPV6_ADDR_GATEWAY'|g' {} \;

if [ ! -f "/confiv/env" ]; then
  echo "Creating file: /config/env" &>>/data/log/entrypoint.log
  cat <<EOF >/config/env
RNDC_KEY="${RNDC_KEY:-}"
OLD_DATE="${OLD_DATE:-2018020901}"
NETDEV="$(ip route 2>/dev/null | grep default | sed -e "s/^.*dev.//" -e "s/.proto.*//" | awk '{print $1}')"
IPV4_ADDR="$(ifconfig $NETDEV 2>/dev/null | grep -E "venet|inet" | grep -v "127.0.0." | grep 'inet' | grep -v inet6 | awk '{print $2}' | sed s/addr://g | head -n1 | grep '^' || echo '')"
IPV6_ADDR="$(ifconfig "$NETDEV" 2>/dev/null | grep -E "venet|inet" | grep 'inet6' | grep -i global | awk '{print $2}' | head -n1 | grep '^' || echo '')"
IPV4_ADDR="${IPV4_ADDR:-10.0.0.2}"
IPV4_ADDR_SUBNET="${IPV4_ADDR_SUBNET:-10.0.0.0}"
IPV4_ADDR_START="${IPV4_ADDR_START:-10.0.100.1}"
IPV4_ADDR_END="${IPV4_ADDR_END:-10.0.100.254}"
IPV4_ADDR_NETMASK="${IPV4_ADDR_NETMASK:-255.255.0.0}"
IPV4_ADDR_GATEWAY="${IPV4_ADDR_GATEWAY:-10.0.0.1}"
IPV6_ADDR="${IP6_ADDR:-2001:0db8:edfa:1234::2}"
IPV6_ADDR_SUBNET="${IPV6_ADDR_SUBNET:-2001:0db8:edfa:1234::}"
IPV6_ADDR_START="${IPV6_ADDR_START:-2001:0db8:edfa:1234:5678::1}"
IPV6_ADDR_END="${IPV6_ADDR_END:-2001:0db8:edfa:1234:5678::ffff}"
IPV6_ADDR_NETMASK="${IPV6_ADDR_NETMASK:-64}"
IPV6_ADDR_GATEWAY="${IPV6_ADDR_GATEWAY:-2001:0db8:edfa:1234::1}"

EOF
fi

if [[ -n "$IP6_ADDR" ]]; then
  if [[ -f "/config/dhcp/dhcpd6.conf" ]]; then
    echo "Initializing dhcpd6" &>>/data/log/entrypoint.log
    cp -Rf "/config/dhcp/dhcpd6.conf" "/etc/dhcp/dhcpd6.conf"
    touch /var/lib/dhcp/dhcpd6.leases
    dhcpd -6 -cf /etc/dhcp/dhcpd6.conf &>>/data/log/dhcpd6.log &
    sleep .5
  fi
  if [[ -f "/config/radvd.conf" ]]; then
    echo "Initializing radvd" &>>/data/log/entrypoint.log
    cp -Rf "/config/radvd.conf" "/etc/radvd.conf"
    radvd -C /etc/radvd.conf &>>/data/log/radvd.log &
    sleep .5
  fi
fi

if [[ -f "/config/dhcp/dhcpd4.conf" ]]; then
  echo "Initializing dhcpd4" &>>/data/log/entrypoint.log
  cp -Rf "/config/dhcp/dhcpd4.conf" "/etc/dhcp/dhcpd4.conf"
  touch /var/lib/dhcp/dhcpd.leases
  dhcpd -4 -cf /etc/dhcp/dhcpd4.conf &>>/data/log/dhcpd4.log &
  sleep .5
fi

if [[ -d "/config/tor" ]]; then
  echo "Initializing tor" &>>/data/log/entrypoint.log
  [[ -d "/config/tor" ]] && cp -Rf "/config/tor" "/etc/tor"
  chown -Rf root:root "/var/lib/tor"
  tor -f "/etc/tor/torrc" &>>/data/log/tor.log &
fi
if [[ -d "/data/tftp" ]]; then
  echo "Initializing tftp" &>>/data/log/entrypoint.log
  rm -Rf "/var/tftpboot"
  ln -sf "/data/tftp" "/var/tftpboot"
  in.tftpd -L /var/tftpboot &>/data/log/tftpd.log &
fi
if [[ -f "/data/web/index.php" ]]; then
  php_bin="$(command -v php || command -v php8 || false)"
  if [[ -n "$php_bin" ]]; then
    echo "Initializing web on $IP_ADDR" &>>/data/log/entrypoint.log
    $php_bin -S 0.0.0.0:80 -t "/data/web" &>>/data/log/php.log &
    sleep .5
  fi
fi
if [[ -f "/config/named.conf" ]]; then
  echo "Initializing named" &>>/data/log/entrypoint.log
  cp -Rf "/config/named.conf" "/etc/named.conf"
  [[ -d "/data/log/dns" ]] || mkdir -p "/data/log/dns"
  [[ -d "/data/named" ]] && cp -Rf "/data/named" "/var/named"
  [[ -d "/config/named" ]] && cp -Rf "/config/named" "/etc/named"
  [[ -f "/config/rndc.key" ]] && cp -Rf "/config/rndc.key" "/etc/rndc.key"
  [[ -f "/config/rndc.conf" ]] && cp -Rf "/config/rndc.conf" "/etc/rndc.conf"
  chmod -f 777 "/data/log/dns"
  __run_dns &>>/data/log/named.log &
  sleep .5
fi
sleep 5
date +'%Y-%m-%d %H:%M' >/data/log/entrypoint.log
echo "Initializing completed" &>>/data/log/entrypoint.log
tail -n 1000 -f /data/log/*.log
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
exit ${exitCode:-$?}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# end
