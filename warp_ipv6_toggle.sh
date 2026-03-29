#!/bin/bash
# WARP IPv6 Toggle Script
# Usage: ./warp_ipv6_toggle.sh [enable|disable|status]

set -e

WARP_DIR="/opt/hiddify-manager/other/warp/wireguard"
WARP_CONF="/etc/wireguard/warp.conf"

function check_root() {
    if [ "$EUID" -ne 0 ]; then 
        echo "Error: This script must be run as root"
        exit 1
    fi
}

function check_warp_installed() {
    if [ ! -d "$WARP_DIR" ]; then
        echo "Error: WARP not found at $WARP_DIR"
        exit 1
    fi
    
    if ! systemctl is-active wg-quick@warp >/dev/null 2>&1 && ! systemctl is-enabled wg-quick@warp >/dev/null 2>&1; then
        echo "Error: WARP service not installed or not running"
        echo "Please enable WARP in Hiddify Panel first"
        exit 1
    fi
}

function check_ipv6_available() {
    if curl -6 --connect-timeout 2 -s https://v6.ident.me/ > /dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

function get_ipv6_status() {
    if [ ! -f "$WARP_CONF" ]; then
        echo "disabled"
        return
    fi
    
    if grep -q "oif warp" "$WARP_CONF" 2>/dev/null; then
        echo "enabled"
    else
        echo "disabled"
    fi
}

function enable_ipv6() {
    echo "Enabling IPv6 for WARP..."
    
    # Check if IPv6 is available on host
    if ! check_ipv6_available; then
        echo "Error: IPv6 is not available on the host"
        echo "Please enable IPv6 on your server first"
        exit 1
    fi
    
    # Stop WARP
    systemctl stop wg-quick@warp 2>/dev/null || true
    
    # Clean up old IPv6 routing rules (if any exist)
    echo "Cleaning up old IPv6 rules..."
    ip -6 rule del pref 999 2>/dev/null || true
    ip -6 rule del pref 1000 2>/dev/null || true
    ip -6 route del default dev warp table 51820 2>/dev/null || true
    
    # Backup current config
    if [ -f "$WARP_CONF" ]; then
        cp "$WARP_CONF" "${WARP_CONF}.backup.$(date +%Y%m%d_%H%M%S)"
    fi
    
    cd "$WARP_DIR"
    
    # Remove old profile
    rm -f wgcf-profile.conf
    
    # Regenerate with IPv6 support
    ./wgcf generate >/dev/null 2>&1
    
    # Add Table = off
    sed -i 's/\[Peer\]/Table = off\n\[Peer\]/g' wgcf-profile.conf
    
    # Extract IPv6 address
    ipv6_addr=$(grep -oP 'Address = [^,]+, \K[0-9a-fA-F:]+/\d+' wgcf-profile.conf | head -1)
    
    if [ -n "$ipv6_addr" ]; then
        # Add IPv6 routing rules
        sed -i "/^MTU = /a PostUp = ip -6 route add default dev warp table 51820\nPostUp = ip -6 rule add from ${ipv6_addr} table 51820 pref 1000\nPostUp = ip -6 rule add oif warp table 51820 pref 999\nPostDown = ip -6 rule del oif warp table 51820 pref 999\nPostDown = ip -6 rule del from ${ipv6_addr} table 51820 pref 1000\nPostDown = ip -6 route del default dev warp table 51820" wgcf-profile.conf
        
        echo "✓ IPv6 routing rules added"
    else
        echo "Error: Could not extract IPv6 address from config"
        exit 1
    fi
    
    # Comment out DNS
    sed -i '/DNS = 1.1.1.1/s/^/# /' wgcf-profile.conf
    
    # Link to wireguard config
    mkdir -p /etc/wireguard/
    ln -sf $(pwd)/wgcf-profile.conf "$WARP_CONF"
    
    # Restart WARP
    systemctl restart wg-quick@warp
    
    sleep 2
    
    # Test IPv6
    if curl -6 --interface warp --connect-timeout 3 -s https://v6.ident.me/ > /dev/null 2>&1; then
        ipv6_test=$(curl -6 --interface warp --connect-timeout 3 -s https://v6.ident.me/ 2>/dev/null)
        echo "✓ IPv6 enabled successfully!"
        echo "  WARP IPv6 address: $ipv6_test"
        return 0
    else
        echo "✗ IPv6 enabled but not working"
        echo "  Check logs: journalctl -u wg-quick@warp -n 20"
        return 1
    fi
}

function disable_ipv6() {
    echo "Disabling IPv6 for WARP..."
    
    # Stop WARP
    systemctl stop wg-quick@warp 2>/dev/null || true
    
    # Clean up IPv6 routing rules
    echo "Cleaning up IPv6 rules..."
    ip -6 rule del pref 999 2>/dev/null || true
    ip -6 rule del pref 1000 2>/dev/null || true
    ip -6 route del default dev warp table 51820 2>/dev/null || true
    
    # Backup current config
    if [ -f "$WARP_CONF" ]; then
        cp "$WARP_CONF" "${WARP_CONF}.backup.$(date +%Y%m%d_%H%M%S)"
    fi
    
    cd "$WARP_DIR"
    
    # Remove old profile
    rm -f wgcf-profile.conf
    
    # Regenerate config
    ./wgcf generate >/dev/null 2>&1
    
    # Add Table = off
    sed -i 's/\[Peer\]/Table = off\n\[Peer\]/g' wgcf-profile.conf
    
    # Remove IPv6 addresses
    sed -i '/Address = [0-9a-fA-F:]\{4,\}/s/^/# /' wgcf-profile.conf
    
    # Comment out DNS
    sed -i '/DNS = 1.1.1.1/s/^/# /' wgcf-profile.conf
    
    # Link to wireguard config
    mkdir -p /etc/wireguard/
    ln -sf $(pwd)/wgcf-profile.conf "$WARP_CONF"
    
    # Restart WARP
    systemctl restart wg-quick@warp
    
    echo "✓ IPv6 disabled successfully"
}

function show_status() {
    echo "WARP IPv6 Status"
    echo "================"
    echo ""
    
    status=$(get_ipv6_status)
    echo "Status: $status"
    echo ""
    
    if [ "$status" == "enabled" ]; then
        echo "Configuration:"
        grep -A 3 "PostUp.*oif warp" "$WARP_CONF" 2>/dev/null | sed 's/^/  /' || echo "  No IPv6 rules found"
        echo ""
        
        echo "Testing connectivity..."
        if curl -6 --interface warp --connect-timeout 3 -s https://v6.ident.me/ > /dev/null 2>&1; then
            ipv6_addr=$(curl -6 --interface warp --connect-timeout 3 -s https://v6.ident.me/ 2>/dev/null)
            echo "  ✓ IPv6 is working: $ipv6_addr"
        else
            echo "  ✗ IPv6 is not working"
        fi
    else
        echo "IPv6 is disabled for WARP"
    fi
    
    echo ""
    echo "Host IPv6:"
    if check_ipv6_available; then
        host_ipv6=$(curl -6 --connect-timeout 2 -s https://v6.ident.me/ 2>/dev/null)
        echo "  ✓ Available: $host_ipv6"
    else
        echo "  ✗ Not available"
    fi
}

# Main
check_root
check_warp_installed

case "${1:-status}" in
    enable)
        enable_ipv6
        ;;
    disable)
        disable_ipv6
        ;;
    status)
        show_status
        ;;
    *)
        echo "Usage: $0 [enable|disable|status]"
        echo ""
        echo "Commands:"
        echo "  enable  - Enable IPv6 for WARP"
        echo "  disable - Disable IPv6 for WARP"
        echo "  status  - Show current IPv6 status"
        exit 1
        ;;
esac
