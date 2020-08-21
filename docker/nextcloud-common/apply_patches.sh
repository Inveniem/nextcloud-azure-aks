#!/usr/bin/env sh

set -e
set -u

cd /usr/src/nextcloud

for patch_file in $(find /usr/src/nextcloud/bundled-patches/ -name '*.patch'); do
    echo "Applying patch '${patch_file}'..."
    patch -p1 < "$patch_file"
done

# Clean-up patches to avoid code signing warnings
rm -rf /usr/src/nextcloud/bundled-patches/
