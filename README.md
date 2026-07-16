<div align="center">
<h1>owrt-dev-suite</h1>
<h3>Advanced & highly customizable build script for OpenWRT</h3>

![GitHub release](https://img.shields.io/github/v/release/catspeed-cc/owrt-dev-suite)
![License](https://img.shields.io/github/license/catspeed-cc/owrt-dev-suite)
![GitHub stars](https://img.shields.io/github/stars/catspeed-cc/owrt-dev-suite?style=social)
![GitHub watchers](https://img.shields.io/github/watchers/catspeed-cc/owrt-dev-suite?style=social)
![GitHub forks](https://img.shields.io/github/forks/catspeed-cc/owrt-dev-suite?style=social)
![GitHub issues](https://img.shields.io/github/issues/catspeed-cc/owrt-dev-suite)
![GitHub pull requests](https://img.shields.io/github/issues-pr/catspeed-cc/owrt-dev-suite)
![GitHub last commit](https://img.shields.io/github/last-commit/catspeed-cc/owrt-dev-suite/development)

</div>

-----

`owrt-dev-suite` is a full development suite for OpenWRT developers intending to port devices to OpenWRT. These are the tools built (using AI) to help me port the TRENDnet TEW-829DRU router (also using AI) after they sent me an EOL notice in early 2026. The centrepiece of the suite is of course, the advanced build script itself, which is highly configurable, customizable for your workflow, and designed to save you time.

-----

## 🔀 Table of Contents

- [✨ Features](#-features)
- [🔮 Planned Features](#-planned-features)
- [⚙️ Configuration](#️-configuration)
- [📦 Installation & Upgrade](#-installation--upgrade-procedure)
- [💻 Usage](#-usage)
- [🛠️ OpenWRT Dev Suite Utils](#️-openwrt-developer-suite-utils)
- [🤝 Support](#-support)
- [💡 Contributing](#-contributing)
- [📜 License](#-license)

-----

## 🚀 Features
- 🔧 Highly configurable build environment via `etc/config.sh`
- 📂 Adaptable to personal `~/work` directory structures
- 📦 Automatic DTS injection & calibration data handling
- 🛠️ Support for both patch-based & raw driver modifications (unlimited)
- 📊 Detailed build summaries with elapsed time tracking
- 🧹 Automated cleanup of temporary patches & modified files post-build
- 🐁 Advanced trapping logic with gating mechanisms to ensure cleanup activates only once
- 🔍 Flexible verbosity levels (`-v`, `-vv`) & single-core compile option (`-s`)
- 📥 Automatically copies built images to `~/work/images-out`
- 🌐 Automatically deploys built images to your webserver

## 🔮 Planned Features
- 📦 Multi-version & multi-port/multi-device support with git integration (by v1.1.0)
- 📇 Manages a built image catalogue & download directory for all SOC/MFR/model/OpenWRT versions on your webserver (by v1.1.0)
- 🏗️ Automated setup of minimal required ~/work and ~/projects/ directory structuress(by v1.0.0)

-----

## ⚙️ Configuration
For one time configuration instructions please see [docs/CONFIGURATION.md](docs/CONFIGURATION.md)

## 📦 Installation & Upgrade Procedure
For one time installation & upgrade procedures please see [docs/INSTALLATION.md](docs/INSTALLATION.md)

## 💻 Usage
For a basic build without a make clean and with verbose you run `owrt-build-script -v`

For usage instructions please see [docs/USAGE.md](docs/USAGE.md)

## 🌐 Webserver Integration
For webserver integration instructions please see [docs/WEBSERVER_CPY_SETUP.md](docs/WEBSERVER_CPY_SETUP.md)

## 🛠️ OpenWRT Developer Suite Utils

`catspeed-cc/owrt-dev-suite-utils` is integrated within this GPLv2-or-later project which contains useful scripts for probing GPIO's. Though please proceed at your own risk 😅

For advanced porting tools (GPIO Probe, DTS Extractor, etc.) to use in your GPLv2-or-later project, see the dedicated **GPLv2 `catspeed-cc/owrt-dev-suite-utils`** repository:<br />
👉 [github.com/catspeed-cc/owrt-dev-suite-utils](https://github.com/catspeed-cc/owrt-dev-suite-utils)

## 🤝 Support
Found a bug? Have an idea? Open an issue on our [GitHub Issues](https://github.com/catspeed-cc/owrt-dev-suite/issues) tracker.

If you have exhausted all other options and require direct assistance as a last resort, you may email [mooleshacat@catspeed.cc](mailto:mooleshacat@catspeed.cc).

## 💡 Contributing
Want to help? See [CONTRIBUTING.md](https://github.com/catspeed-cc/owrt-dev-suite/blob/development/CONTRIBUTING.md) for guidelines, bug reports, and feature requests.

## 📜 License
This project is licensed under the **GPLv2 or later** for full compatibility with OpenWRT & Kernel licenses. See [LICENSE](LICENSE) for details.

## 🛡️ Supporting Software Freedom
❤️ We proudly support the work of the **Software Freedom Conservancy**, who fight to uphold GPL compliance so projects like this one remain possible.
<div align="center">
  <a href="https://sfconservancy.org/sustainer/">
    <img src="https://sfconservancy.org/static/img/supporter-badge.png" width="194" height="90" alt="Become a Conservancy Sustainer!" border="0"/>
  </a>
</div>
