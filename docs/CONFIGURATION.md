## ⚙️ Configuration
All build parameters, paths, and feature toggles are managed exclusively in `etc/config.sh`. Edit this file to tailor the suite to your workflow.

**Setup work & projects directories:**<br />
For first time setup it is a good idea to create both a `~/projects` and `~/work` directory. You also need a copy of OpenWRT. Replace the soc/mfr/model with your own from your planned port.
```bash
# Make projects directory for development work
mkdir -p ~/projects
cd ~/projects

# Clone openwrt (fetches default branch initially)
git clone https://github.com/openwrt/openwrt.git ~/projects/openwrt-dev
cd ~/projects/openwrt-dev

# Fetch ALL remote branches and tags (critical for accessing all stable versions)
git fetch --all

# Set up minimal required ~/work directory for build script features
mkdir -p ~/work/ports
cd ~/work/ports
mkdir -p ipq40xx/trendnet/tew-829dru
mkdir -p ipq40xx/trendnet/tew-829dru/dts/oem
mkdir -p ipq40xx/trendnet/tew-829dru/patches
mkdir -p ipq40xx/trendnet/tew-829dru/driver-mod
mkdir -p ipq40xx/trendnet/tew-829dru/image-out
mkdir -p ipq40xx/trendnet/tew-829dru/caldata

# Create a driver mod directory if you plan to make one (example)
mkdir -p ipq40xx/trendnet/tew-829dru/driver-mod/ipqess-dual-netdev
```

**Submodule Initialization:**<br />
To ensure all utility scripts are properly linked, run one of the following commands:
```bash
# Clone the repository
cd ~/projects && git clone --recursive --remote https://github.com/catspeed-cc/owrt-dev-suite.git
# OR if already cloned:
cd ~/projects/owrt-dev-suite && git submodule update --init --recursive --remote
```

These initial configuration steps will be automated in future versions.
