#!/bin/sh

# This script clones the internal root filesystem to an external device on OpenWrt.

# Create mount points for internal and external root filesystems
mkdir -p /tmp/introot
mkdir -p /tmp/extroot

# Bind mount the internal root filesystem to a temporary location
mount --bind / /tmp/introot

# Mount the external device to another temporary location
mount /dev/sda1 /tmp/extroot

# Copy the contents from the internal root filesystem to the external device
tar -C /tmp/introot -cvf - . | tar -C /tmp/extroot -xf -

# Unmount the temporary mount points
umount /tmp/introot
umount /tmp/extroot

echo "Cloning complete."
