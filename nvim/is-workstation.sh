#!/bin/sh
# Exit successfully only for positively identified, supported workstations.
kernel="$(uname -s 2>/dev/null)" || exit 1
case "$kernel" in
    Darwin) exit 0 ;;
    Linux) ;;
    *) exit 1 ;;
esac

[ -r /etc/os-release ] || exit 1
ID=''
VARIANT_ID=''
# shellcheck disable=SC1091
. /etc/os-release || exit 1

case "$ID" in
    ubuntu)
        case "$VARIANT_ID" in ''|desktop|workstation) ;; *) exit 1 ;; esac
        desktop_installed=0
        for package in ubuntu-desktop ubuntu-desktop-minimal; do
            if status="$(dpkg-query -W -f='${Status}' "$package" 2>/dev/null)" && [ "$status" = 'install ok installed' ]; then
                desktop_installed=1
                break
            fi
        done
        [ "$desktop_installed" = 1 ] || exit 1
        ;;
    fedora)
        [ "$VARIANT_ID" = workstation ] || exit 1
        rpm -q fedora-release-workstation >/dev/null 2>&1 || exit 1
        ;;
    *) exit 1 ;;
esac

# Missing tools and detection errors deny access, just like confirmed containers.
virt_status=0
virtualization="$(systemd-detect-virt --container 2>/dev/null)" || virt_status=$?
[ "$virt_status" -eq 1 ] && [ "$virtualization" = none ] || exit 1
default_target="$(systemctl get-default 2>/dev/null)" || exit 1
[ "$default_target" = graphical.target ] || exit 1
display_manager="$(systemctl show display-manager.service --property=LoadState --value 2>/dev/null)" || exit 1
[ "$display_manager" = loaded ] || exit 1
