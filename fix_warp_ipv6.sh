#!/bin/bash
# Script to automatically fix WARP IPv6 support
# This script applies the IPv6 routing fix to WARP configuration

set -e

echo "=========================================="
echo "WARP IPv6 Fix - Automatic Installation"
echo "=========================================="
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "Error: This script must be run as root"
    exit 1
fi

# Check if Hiddify Manager is installed
if [ ! -d "/opt/hiddify-manager" ]; then
    echo "Error: Hiddify Manager not found at /opt/hiddify-manager"
    exit 1
fi

cd /opt/hiddify-manager

echo "Step 1: Regenerating configurations from templates..."
bash apply_configs.sh > /dev/null 2>&1
echo "✓ Configurations regenerated"

echo ""
echo "Step 2: Checking if WARP is enabled..."
if systemctl is-enabled wg-quick@warp > /dev/null 2>&1; then
    echo "✓ WARP is enabled"
    
    echo ""
    echo "Step 3: Stopping WARP service..."
    systemctl stop wg-quick@warp
    echo "✓ WARP stopped"
    
    echo ""
    echo "Step 4: Regenerating WARP configuration..."
    cd /opt/hiddify-manager/other/warp/wireguard
    
    # Backup existing config
    if [ -f "wgcf-profile.conf" ]; then
        cp wgcf-profile.conf wgcf-profile.conf.backup.$(date +%Y%m%d_%H%M%S)
        rm wgcf-profile.conf
    fi
    
    # Run WARP setup
    bash run.sh > /tmp/warp_setup.log 2>&1
    
    if [ $? -eq 0 ]; then
        echo "✓ WARP configuration regenerated"
    else
        echo "✗ Error regenerating WARP configuration"
        echo "Check /tmp/warp_setup.log for details"
        exit 1
    fi
    
    echo ""
    echo "Step 5: Verifying IPv6 routing rules..."
    if grep -q "oif warp" /etc/wireguard/warp.conf; then
        echo "✓ IPv6 routing rules found in configuration"
        echo ""
        echo "Configuration preview:"
        echo "---"
        grep -A 3 "PostUp.*oif warp" /etc/wireguard/warp.conf | sed 's/^/  /'
        echo "---"
    else
        echo "✗ Warning: IPv6 routing rules not found in configuration"
        echo "This might indicate that IPv6 is not available on the host"
    fi
    
    echo ""
    echo "Step 6: Testing IPv6 connectivity through WARP..."
    sleep 2
    
    # Test IPv6 through WARP
    if curl -6 --interface warp --connect-timeout 3 -s https://v6.ident.me/ > /dev/null 2>&1; then
        ipv6_addr=$(curl -6 --interface warp --connect-timeout 3 -s https://v6.ident.me/ 2>/dev/null)
        echo "✓ IPv6 through WARP is working!"
        echo "  Your WARP IPv6 address: $ipv6_addr"
    else
        echo "✗ IPv6 through WARP is not working"
        echo "  Checking if IPv6 is available on host..."
        if curl -6 --connect-timeout 2 -s https://v6.ident.me/ > /dev/null 2>&1; then
            host_ipv6=$(curl -6 --connect-timeout 2 -s https://v6.ident.me/ 2>/dev/null)
            echo "  Host IPv6 is working: $host_ipv6"
            echo "  But WARP IPv6 is not working. Check logs:"
            echo "  journalctl -u wg-quick@warp -n 20"
        else
            echo "  IPv6 is not available on the host"
        fi
    fi
    
else
    echo "✗ WARP is not enabled"
    echo "Enable WARP in Hiddify Panel first"
    exit 1
fi

echo ""
echo "=========================================="
echo "Installation completed!"
echo "=========================================="
echo ""
echo "WARP will now automatically use IPv6 after each reboot."
echo ""
echo "Useful commands:"
echo "  - Check WARP status: systemctl status wg-quick@warp"
echo "  - Test IPv6: curl -6 --interface warp https://v6.ident.me/"
echo "  - View config: cat /etc/wireguard/warp.conf"
echo "  - View logs: journalctl -u wg-quick@warp -f"
echo ""
