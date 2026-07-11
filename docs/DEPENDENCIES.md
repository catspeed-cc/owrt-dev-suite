# System Dependencies:
Before cloning the repository, ensure your host system has the required build tools installed.

<details>
<summary><strong>Debian / Ubuntu (Bookworm, Jammy+)</strong></summary>

```bash
sudo apt update
sudo apt install -y binutils bzip2 diffutils findutils flex gawk gcc util-linux \
    grep coreutils libc6-dev zlib1g-dev make perl python3 rsync subversion unzip gnu-which
```
*Note: On Debian/Ubuntu, installing `build-essential` covers most core compilation tools.*
</details>

<details>
<summary><strong>Fedora / RHEL</strong></summary>

```bash
sudo dnf install -y binutils bzip2 diffutils findutils flex gawk gcc util-linux \
    grep glibc-devel zlib-devel make perl python3 rsync subversion unzip which
```
</details>

<details>
<summary><strong>Arch Linux</strong></summary>

```bash
sudo pacman -S --needed binutils bzip2 diffutils findutils flex gawk gcc util-linux \
    grep glibc zlib make perl python rsync subversion unzip which
```
</details>

The script will detect and prompt to install missing dependencies (above) as needed
