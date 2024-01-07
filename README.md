# OpenWRT-Automate-BASH-Scripts
Scripts that automate tedious tasks when dealing with OpenWRT routers.

## What they do?  
`usb-extroot.sh` - this will format and setup any usb stick and set it to use extroot. This means the USB stick will be mounted `root` and `/overlay` partitions so that there is more space to download packages. This is useful if your router has a very small amount of memory. See https://openwrt.org/docs/guide-user/additional-software/extroot_configuration for more info, the script basically follows the guide step by step and will gie you some output and information on what it is doing.

## How to run  
It is probably best to download and upload the script manually and upload it to the router yourself via ssh since ccloning the repo will ask you for verification for github bla bla... Just download the script and send it over SCP.
