# WARP IPv6 Fix

## Problem Description

WARP was not working with IPv6 even when IPv6 was available on the host. This was caused by:

1. **Incorrect IPv6 detection**: The curl command didn't force IPv6, so it could connect via IPv4 and incorrectly report that IPv6 was working
2. **Missing routing rules**: Even when IPv6 was configured, there were no policy-based routing rules to route traffic through the WARP interface

## Solution

This fix adds:

1. **Proper IPv6 detection**: Uses `curl -6` flag to force IPv6-only connections
2. **Policy-based routing for IPv6**: Adds routing rules to ensure IPv6 traffic goes through WARP:
   - Creates a separate routing table (51820) for WARP
   - Adds rule for traffic from WARP IPv6 address
   - Adds rule for all outgoing traffic through WARP interface (`oif warp`)

## Automatic Installation

Run the automated fix script:

```bash
cd /opt/hiddify-manager
chmod +x fix_warp_ipv6.sh
./fix_warp_ipv6.sh
```

The script will:
1. Regenerate all configurations from templates
2. Stop WARP service
3. Regenerate WARP configuration with IPv6 routing rules
4. Verify the fix
5. Test IPv6 connectivity through WARP

## Manual Installation

If you prefer to apply the fix manually:

```bash
# 1. Pull the latest changes
cd /opt/hiddify-manager
git pull

# 2. Regenerate configurations
bash apply_configs.sh

# 3. Recreate WARP configuration
cd /opt/hiddify-manager/other/warp/wireguard
systemctl stop wg-quick@warp
rm wgcf-profile.conf
bash run.sh

# 4. Verify the fix
cat /etc/wireguard/warp.conf | grep "oif warp"

# 5. Test IPv6
curl -6 --interface warp --connect-timeout 2 https://v6.ident.me/
```

## Verification

After applying the fix, verify that IPv6 is working:

```bash
# Check WARP configuration has IPv6 routing rules
cat /etc/wireguard/warp.conf

# Should contain these lines:
# PostUp = ip -6 route add default dev warp table 51820
# PostUp = ip -6 rule add from <ipv6_addr> table 51820 pref 1000
# PostUp = ip -6 rule add oif warp table 51820 pref 999

# Test IPv6 connectivity
curl -6 --interface warp https://v6.ident.me/

# Check routing rules
ip -6 rule show
ip -6 route show table 51820
```

## Technical Details

### Files Modified

1. **other/warp/wireguard/run.sh.j2**: Template for WireGuard WARP setup script
   - Added `-6` flag to curl for proper IPv6 detection
   - Added PostUp/PostDown rules for IPv6 routing

2. **other/warp/singbox/run.sh**: Sing-box WARP setup script
   - Added `-6` flag to curl for proper IPv6 detection

### Routing Rules Explained

When IPv6 is available, the following rules are added to `/etc/wireguard/warp.conf`:

```bash
# Create default route in table 51820 through warp interface
PostUp = ip -6 route add default dev warp table 51820

# Route traffic from WARP IPv6 address through table 51820
PostUp = ip -6 rule add from 2606:4700:110:xxxx:xxxx:xxxx:xxxx:xxxx/128 table 51820 pref 1000

# Route all outgoing traffic through warp interface to table 51820
PostUp = ip -6 rule add oif warp table 51820 pref 999

# Cleanup rules on shutdown
PostDown = ip -6 rule del oif warp table 51820 pref 999
PostDown = ip -6 rule del from 2606:4700:110:xxxx:xxxx:xxxx:xxxx:xxxx/128 table 51820 pref 1000
PostDown = ip -6 route del default dev warp table 51820
```

The key rule is `oif warp` (outgoing interface), which ensures that when Xray/Sing-box uses `bind_interface: "warp"`, the IPv6 traffic is properly routed through the WARP tunnel.

## Troubleshooting

### IPv6 still not working after fix

1. Check if IPv6 is available on host:
   ```bash
   curl -6 https://v6.ident.me/
   ```

2. Check WARP service status:
   ```bash
   systemctl status wg-quick@warp
   journalctl -u wg-quick@warp -n 50
   ```

3. Check routing rules:
   ```bash
   ip -6 rule show
   ip -6 route show table 51820
   ```

4. Test ICMP (ping) vs TCP:
   ```bash
   # ICMP should work
   ping6 -I warp -c 3 2606:4700:4700::1111
   
   # TCP should also work
   curl -6 --interface warp https://v6.ident.me/
   ```

### IPv6 removed from WARP config

If you see "Removing IPV6 from WARP..." during setup, it means:
- IPv6 is not available on the host, OR
- IPv6 is disabled in system settings

Check:
```bash
# Should return 0 (enabled)
cat /proc/sys/net/ipv6/conf/all/disable_ipv6

# Should succeed
curl -6 https://v6.ident.me/
```

## Persistence

The fix is persistent across reboots because:
1. The routing rules are in `/etc/wireguard/warp.conf` as PostUp/PostDown commands
2. The `wg-quick@warp` service is enabled and starts automatically
3. The template file `run.sh.j2` contains the fix, so any future regeneration will include it

## Credits

Fix developed to resolve IPv6 connectivity issues in Hiddify Manager WARP integration.
