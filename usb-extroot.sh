#!/bin/ash

echo -e "\033[1;92mListing block devices:\033[0m"
ls -l /sys/block

sleep 5

echo -e "\033[1;92mPlease ensure that the USB stick is the only storage device connected other than the root device.\033[0m"
echo -e "\033[1;92mPartitioning and formatting USB stick...\033[0m"
DISK="/dev/sda" # Consider prompting the user or detecting the USB stick automatically
parted -s ${DISK} -- mklabel gpt mkpart extroot 2048s -2048s
DEVICE="${DISK}1"
mkfs.ext4 -L extroot ${DEVICE}

UUID=$(block info ${DEVICE} | grep -o -e 'UUID="\S*"' | sed 's/UUID=//g' | tr -d '"')
MOUNT=$(block info | grep -o -e 'MOUNT="\S*/overlay"' | sed 's/MOUNT=//g' | tr -d '"')

if [ -z "${UUID}" ] || [ -z "${MOUNT}" ]; then
  echo -e "\033[1;91mError: Unable to find UUID or MOUNT point.\033[0m"
  exit 1
fi

uci -q delete fstab.extroot
uci set fstab.extroot="mount"
uci set fstab.extroot.uuid="${UUID}"
uci set fstab.extroot.target="${MOUNT}"
uci commit fstab

echo -e "\033[1;92mCommitting changes to fstab...\033[0m"
if mount ${DEVICE} /mnt && tar -C ${MOUNT} -cvf - . | tar -C /mnt -xf - && umount /mnt; then
  echo -e "\033[1;92mSuccessfully copied data to external drive.\033[0m"
else
  echo -e "\033[1;91mFailed to copy data to external drive or unmount.\033[0m"
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

echo -e "\033[1;93mThe device will now be rebooted. Press CTRL+C within the next 20 seconds to cancel the reboot.\033[0m"
sleep 20
reboot
