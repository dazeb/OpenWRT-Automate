#!/bin/ash

# Create a UCI default script for extroot restore
cat << "EOF" > /etc/uci-defaults/90-extroot-restore
# Check if extroot is configured, the restore flag is not set, the init flag is set, and lock the process
if uci -q get fstab.extroot > /dev/null \
&& [ ! -e /etc/extroot-restore ] \
&& [ -e /etc/opkg-restore-init ] \
&& lock -n /var/lock/extroot-restore
then
  # Get the UUID and mount point for the extroot partition
  UUID="$(uci -q get fstab.extroot.uuid)"
  DIR="$(uci -q get fstab.extroot.target)"
  DEV="$(block info | sed -n -e "/${UUID}/s/:.*$//p")"

  # Create a restore flag, check if the mount point is in use, and mount the device
  if touch /etc/extroot-restore \
  && grep -q -e "\s${DIR}\s" /etc/mtab \
  && mount "${DEV}" /mnt
  then
    # Create a temporary backup directory on the mounted device
    BAK="$(mktemp -d -p /mnt -t bak.XXXXXX)"
    if [ -d "${BAK}" ]; then
      # Move the current etc and upper directories to the backup directory
      mv -f /mnt/etc /mnt/upper "${BAK}" && \
      # Copy the contents of the current extroot to the mounted device
      cp -f -a "${DIR}"/. /mnt && \
      # Unmount the device
      umount "${DEV}"
    else
      echo "Failed to create backup directory. Aborting."
      lock -u /var/lock/extroot-restore
      exit 1
    fi
  else
    echo "Failed to mount device or extroot-restore flag already exists."
    lock -u /var/lock/extroot-restore
    exit 1
  fi

  # Unlock the process and reboot the router
  lock -u /var/lock/extroot-restore
  reboot
else
  echo "Extroot is not configured, or opkg-restore-init flag is not set."
fi
exit 1
EOF

# Append to sysupgrade.conf to include the UCI defaults directory
cat << "EOF" >> /etc/sysupgrade.conf
/etc/uci-defaults
EOF
