#!/bin/bash
# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2026 mooleshacat <mooleshacat@catspeed.cc>

# Define package lists as space-separated strings

# Debian/Ubuntu packages
# Debian/Ubuntu (Bookworm/Jammy+)
DEBIAN_PACKAGES="binutils bzip2 diffutils findutils flex gawk gcc util-linux grep coreutils libc6-dev zlib1g-dev make perl python3 rsync subversion unzip gnu-which"

# Fedora/RHEL packages
FEDORA_PACKAGES="binutils bzip2 diffutils findutils flex gawk gcc util-linux grep glibc-devel zlib-devel make perl python3 rsync subversion unzip which"

# Arch packages
ARCH_PACKAGES="binutils bzip2 diffutils findutils flex gawk gcc util-linux grep glibc zlib make perl python rsync subversion unzip which"
