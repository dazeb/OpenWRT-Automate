#!/bin/ash

# Find swap location
DIR="$(uci -q get fstab.extroot.target)"

# Disable and remove the existing swap file
swapoff "${DIR}/swap"
rm -f "${DIR}/swap"

# Create a new swap file of 1GB
dd if=/dev/zero of="${DIR}/swap" bs=1M count=1024
mkswap "${DIR}/swap"

# Enable swap file
uci -q delete fstab.swap
uci set fstab.swap="swap"
uci set fstab.swap.device="${DIR}/swap"
uci commit fstab
service fstab boot

# Verify swap status
cat /proc/swaps
