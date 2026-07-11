## 🌐 Webserver Image Copy & Permissions Setup

To enable seamless deployment, your build user and the webserver user (`www-data`) must share access to a common directory. This setup creates a shared group, configures permissions with the **SetGID** bit (to ensure new files inherit the group), and establishes a symlink to your web root.

> **⚠️ Note:** These initial configuration steps will be automated in future versions of the suite.

### 1. Create Shared Group & Add Users

Create a dedicated group for deployment and add both your user and the webserver user to it.

```bash
# Create the shared group
sudo groupadd openwrt-deployers

# Add your current user to the group
sudo usermod -aG openwrt-deployers $USER

# Add the web server user (www-data) to the group
sudo usermod -aG openwrt-deployers www-data

# Verify group members
getent group openwrt-deployers

# Apply new group membership to your current session
newgrp openwrt-deployers

# Restart your webserver to ensure it recognizes the new group
sudo systemctl restart nginx
```

### 2. Create Directory Structure & Symlink

Create the central storage directory and link it to your webserver's download folder.

```bash
# Create the full directory path for shared builds
sudo mkdir -p /srv/openwrt-builds

# Create a symlink in your webserver's root to the shared directory
# (Adjust /var/www/catspeed.cc/downloads/ to match your actual web root)
cd /var/www/catspeed.cc/downloads/
ln -s /srv/openwrt-builds openwrt-builds

# Verify the link
ls -l openwrt-builds
```

### 3. Configure Permissions (SetGID)

Set ownership to `root:openwrt-deployers` and apply the **2775** permission mode. 
*   **2 (SetGID)**: Forces new files/subdirectories to inherit the `openwrt-deployers` group. 
*   **7 (Owner)**: Root has full access. 
*   **7 (Group)**: You and `www-data` have full read/write/execute access. 
*   **5 (Other)**: Public has read/traverse access (required for web serving). 

```bash
# Create an example port directory structure
sudo mkdir -p /srv/openwrt-builds/ipq40xx/trendnet/tew-829dru/25.12/

# Set ownership: Root (owner) and openwrt-deployers (group)
sudo chown -R root:openwrt-deployers /srv/openwrt-builds 

# Set permissions: 2775 (SetGID + rwxrwxr-x)
sudo chmod -R 2775 /srv/openwrt-builds
```

### Verification

Ensure the permissions are applied correctly:

```bash
ls -ld /srv/openwrt-builds
# Expected output: drwxrwsr-x ... root openwrt-deployers ...
# Note the 's' in the group execute position, indicating SetGID is active.
```
