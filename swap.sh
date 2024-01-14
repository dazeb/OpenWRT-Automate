#!/bin/sh

# Get the target directory from UCI configuration
DIR="$(uci -q get fstab.extroot.target)"

# Check if the directory exists
if [ ! -d "${DIR}" ]; then
   echo "Directory ${DIR} does not exist."
   exit 1
fi

# Create a 100MB swap file in the target directory
dd if=/dev/zero of=${DIR}/swap bs=1M count=100 || { echo "Failed to create swap file."; exit 1; }

# Set up the swap file
mkswap ${DIR}/swap || { echo "Failed to set up swap file."; exit 1; }

# Delete the old swap entry in UCI configuration
uci -q delete fstab.swap

# Add a new swap entry in UCI configuration
uci set fstab.swap="swap"
uci set fstab.swap.device="${DIR}/swap"

# Commit the changes to UCI configuration
uci commit fstab || { echo "Failed to commit changes to UCI configuration."; exit 1; }

# Enable the swap file
service fstab boot || { echo "Failed to enable swap file."; exit 1; }

# Print the status of swap files
cat /proc/swaps
