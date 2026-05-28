#!/bin/bash
set -xe

[ -d build ] || git clone https://gitlab.com/ubports/community-ports/halium-generic-adaptation-build-tools build
./build/build.sh "$@"

# Post-build steps to duplicate the built recovery into rootfs as well. This
# will be used by `device-hacks` script to update recovery post-boot.
# TODO: remove once 24.04-1.x goes EOL.

./include-recovery-in-rootfs.sh "$@"
