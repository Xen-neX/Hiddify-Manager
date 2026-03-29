#!/bin/bash
# Installation script for Hiddify Manager Fork with IPv6 WARP fix
# This script properly installs the fork instead of the original repository

set -e

if [ "$(id -u)" -ne 0 ]; then
    echo 'This script must be run as root' >&2
    exit 1
fi

FORK_REPO="https://github.com/Xen-neX/Hiddify-Manager.git"
INSTALL_DIR="/opt/hiddify-manager"

echo "=========================================="
echo "Hiddify Manager Fork Installer"
echo "=========================================="
echo ""
echo "This will install Hiddify Manager from fork:"
echo "$FORK_REPO"
echo ""
read -p "Continue? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
fi

# Step 1: Clone or update the fork
if [ -d "$INSTALL_DIR" ]; then
    echo "Existing installation found. Creating backup..."
    tar -czf ~/hiddify-backup-$(date +%Y%m%d_%H%M%S).tar.gz \
        $INSTALL_DIR/hiddify-panel/hiddifypanel.db \
        $INSTALL_DIR/ssl \
        $INSTALL_DIR/other/warp/wireguard/wgcf-account.toml 2>/dev/null || true
    
    cd $INSTALL_DIR
    echo "Updating fork repository..."
    git fetch origin
    git reset --hard origin/main
    git clean -fd
else
    echo "Cloning fork repository..."
    cd /opt
    git clone $FORK_REPO hiddify-manager
    cd $INSTALL_DIR
fi

# Step 2: Run the standard Hiddify installer
# This will install hiddifypanel from PyPI and use configs from the cloned fork
echo ""
echo "Running Hiddify installation..."
echo "Note: Panel will be installed from PyPI, configs from fork"
echo ""

# Use the hiddify_installer.sh which handles everything properly
bash common/hiddify_installer.sh release --no-gui

if [ $? -ne 0 ]; then
    echo ""
    echo "Installation failed. Check logs at:"
    echo "  /opt/hiddify-manager/log/system/"
    exit 1
fi

# Step 2.5: Fix database configuration (mariadb -> localhost)
echo ""
echo "Fixing database configuration..."
if [ -f "$INSTALL_DIR/hiddify-panel/app.cfg" ]; then
    # Replace mariadb host with localhost for non-docker installations
    sed -i 's/@mariadb\//@localhost\//g' "$INSTALL_DIR/hiddify-panel/app.cfg"
    echo "✓ Database configuration fixed"
    
    # Restart panel to apply changes
    systemctl restart hiddify-panel
fi

# Step 3: Make IPv6 scripts executable
if [ -f "$INSTALL_DIR/warp_ipv6_toggle.sh" ]; then
    chmod +x $INSTALL_DIR/warp_ipv6_toggle.sh
fi
if [ -f "$INSTALL_DIR/fix_warp_ipv6.sh" ]; then
    chmod +x $INSTALL_DIR/fix_warp_ipv6.sh
fi

echo ""
echo "=========================================="
echo "Installation Complete!"
echo "=========================================="
echo ""
echo "Access your panel at:"
echo "  https://$(curl -s https://v4.ident.me/)"
echo ""
echo "To enable IPv6 for WARP:"
echo "  1. Enable WARP in Hiddify Panel"
echo "  2. Run: cd /opt/hiddify-manager && ./warp_ipv6_toggle.sh enable"
echo ""
echo "Useful commands:"
echo "  systemctl status hiddify-panel"
echo "  systemctl status wg-quick@warp"
echo "  journalctl -u hiddify-panel -f"
echo ""
