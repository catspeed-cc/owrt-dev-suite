## 📦 Installation & Upgrade Procedure

### Installation: Clone the Repository

1. **Clone the repository with submodules:**
```bash
git clone --recursive --remote https://github.com/catspeed-cc/owrt-dev-suite.git
cd ~/projects/owrt-dev-suite
```

2. **Verify Dependencies:**
   Ensure you have a compatible OpenWRT source tree (e.g., `openwrt-dev`) and required host build dependencies installed.

3. **Configure:**
   Edit `etc/config.sh` to set your working directories, paths, and toggle features according to your needs.

---

### Upgrade & Branch Management

**⚠️ Warning:** Checking out `master` and pulling can introduce breaking changes. You may be upgraded to a major version requiring manual changes to configs before the suite works again.

To update to the latest development version:
```bash
cd ~/projects/owrt-dev-suite
git checkout master
git pull
git submodule update --init --recursive --remote
```

---

### 🔖 Pinning to a Specific Version (Tags)

For production stability, it is recommended to **pin** your installation to a specific release tag. This ensures your build environment remains consistent even if the `master` branch changes.

1. **Fetch all available tags:**
```bash
cd ~/projects/owrt-dev-suite
git fetch --all --tags
```

2. **List available versions:**
   View all release tags to find the version you want (e.g., `v1.0.0`, `v1.2.3`).
```bash
git tag -l
```

3. **Checkout a specific tag:**
   Replace `<tag_name>` with your desired version (e.g., `v1.0.0`).
```bash
git checkout tags/<tag_name>
```
   *Note: This puts you in a "detached HEAD" state, which is normal for pinned versions.*

4. **Initialize submodules for that version:**
   Ensure submodules match the pinned version.
```bash
git submodule update --init --recursive
```

> **💡 Tip:** To return to the latest `master` version later, simply run `git checkout master` and pull again.
> **💡 Tip:** To return to the latest `development` version later, simply run `git checkout development` and pull again.
