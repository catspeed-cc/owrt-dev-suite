## 💻 Usage
Run the main build script from the repository root:
```bash
~/projects/owrt-dev-suite/owrt-build-release [OPTIONS]
```

**Available options:**
- `-clean`, `-c` : Run `make clean` and update feeds before building
- `-updatefeeds`, `-uf` : Update and install OpenWRT feeds
- `-verbose`, `-v` : Enable verbose make output
- `-extraverbose`, `-vv` : Enable extra verbose make output (`V=99`)
- `-slow`, `-s` : Force single-core compilation (disables parallel jobs)
- `--help`, `-h` : Display this help message

Examples:
```bash
# Enter openwrt project directory
cd ~/projects/openwrt-dev

# Full flags
~/projects/owrt-dev-suite/owrt-build-release -clean -updatefeeds -verbose # clean build to build in new menuconfig packages, caldata, patch or drivermod changes
~/projects/owrt-dev-suite/owrt-build-release -verbose # clean build to build in new menuconfig packages, caldata, patch or drivermod changes

# Short flags
~/projects/owrt-dev-suite/owrt-build-release -c -uf -v # clean build to build in new menuconfig packages, caldata, patch or drivermod changes
~/projects/owrt-dev-suite/owrt-build-release -v # reuse previous packages, caldata, patch, or drivermod, only build in the updated DTS changes
```

