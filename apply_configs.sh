#!/bin/bash
cd $(dirname -- "$0")
DO_NOT_INSTALL=true ./install.sh apply_configs $@
#DO_NOT_INSTALL=true ./install.sh

# Auto-apply IPv6 fix for WARP if it was enabled before
if [ -f "/etc/wireguard/warp.conf" ]; then
    if grep -q "oif warp" /etc/wireguard/warp.conf 2>/dev/null; then
        echo "Re-applying IPv6 WARP configuration..."
        if [ -f "./warp_ipv6_toggle.sh" ]; then
            bash ./warp_ipv6_toggle.sh enable >/dev/null 2>&1 || true
        fi
    fi
fi
