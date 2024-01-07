#!/bin/ash

echo -e "\033[1;92mListing block devices:\033[0m"
ls -l /sys/block

sleep 5

echo -e "\033[1;92mPartitioning and formatting USB stick...\033[0m"
DISK="/dev/sda"
parted -s ${DISK} -- mklabel gpt mkpart extroot 2048s -2048s
DEVICE="${DISK}1"
mkfs.ext4 -L extroot ${DEVICE}

UUID=$(block info ${DEVICE} | grep -o -e 'UUID="\S*"')
MOUNT=$(block info | grep -o -e 'MOUNT="\S*/overlay"')

uci -q delete fstab.extroot
uci set fstab.extroot="mount"
uci set fstab.extroot.uuid="${UUID}"
uci set fstab.extroot.target="${MOUNT}"
uci commit fstab

echo -e "\033[1;92mCommitting changes to fstab...\033[0m"
if mount ${DEVICE} /mnt && tar -C ${MOUNT} -cvf - . | tar -C /mnt -xf -; then
  echo -e "\033[1;92mSuccessfully copied data to external drive.\033[0m"
else
  echo -e "\033[1;91mFailed to copy data to external drive.\033[0m"
  exit 1
fi

echo -e "\033[1;92mUpdating fstab for read-write mode...\033[0m"
DEVICE="$(block info | sed -n -e '/MOUNT="\S*\/overlay"/s/:\s.*$//p')"
uci -q delete fstab.rwm
uci set fstab.rwm="mount"
uci set fstab.rwm.device="${DEVICE}"
uci set fstab.rwm.target="/rwm"
if uci commit fstab; then
  echo -e "\033[1;92mSuccessfully updated fstab for read-write mode.\033[0m"
else
  echo -e "\033[1;91mFailed to update fstab for read-write mode.\033[0m"
  exit 1
fi

echo -e "\033[1;92mThe device will now be rebooted. Press CTRL+C to cancel the reboot.\033[0m"
sleep 10
reboot
