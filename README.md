# void-install
A Void Linux with Sway window manager install guide and post-install script.


**Guide, post-install script, and dotfiles are not ready for public use. I just have it set as public so I can access it without logging in to GitHub.**

This guide is not a just works solution. You will need to do some configuring yourself and still need to know your way around setting up a bare-bones Linux desktop from scratch.
This install uses seatd instead of elogind.


# Install
The base install of Void. I would recommend installing with [full disk encryption](https://docs.voidlinux.org/installation/guides/fde.html#full-disk-encryption), but you can also use the [install media](https://docs.voidlinux.org/installation/live-images/guide.html), which won't have full disk encryption, but will be easier to install.

## Notes for full disk encryption:
- If you're unsure how to edit files, for example when the guide says to "Add the following line to `/etc/default/grub`", type `vi /etc/default/grub`, this will open the file in the Vim text editor. If you're unfamiliar with using Vim: https://linuxhandbook.com/basic-vim-commands
- When it says "Edit the `GRUB_CMDLINE_LINUX_DEFAULT=` line in `/etc/default/grub`" do not delete what already exists in `GRUB_CMDLINE_LINUX_DEFAULT=`, add to it by putting a space between what already exists and what you're adding
- Run this after you complete the install: `grub-mkconfig -o /boot/grub/grub.cfg`
- If your system uses legacy BIOS (MKR): https://docs.voidlinux.org/installation/live-images/partitions.html#bios-system-notes
- If your system uses UEFI: https://docs.voidlinux.org/installation/live-images/partitions.html#uefi-system-notes
	- When partitioning give the EFI partition 300M size, you can spare 200M
	- When you run `fdisk -l <drive>`, make sure it says `Disklabel type: gpt`
	- Remember that since you have an EFI partition the partition that will be encrypted and installed onto will be `/dev/sda2` or `/dev/nvme0n1p2`. If you're having trouble understanding the filesystems: `/dev/sda` is the drive itself, `/dev/sda1` is the EFI partition, which you need since your system uses UEFI, and `/dev/sda2` is the main partition. If you are using an NVMe drive it will be slightly different, `/dev/nvme0n1` is the drive itself, `/dev/nvme0n1p1` is the EFI partition, and `/dev/nvme0n1p2` is the main partition.
- If you're installing onto an SSD: https://docs.voidlinux.org/config/ssd.html
	- Make these modifications during the install to enable TRIM:
		- When running `cryptsetup luksOpen`, add `--allow-discards`. It should look like `cryptsetup luksOpen --allow-discards /dev/nvme0n1pX voidvm`
		- When it says "Edit the `GRUB_CMDLINE_LINUX_DEFAULT=` line in `/etc/default/grub`" also add `rd.luks.allow-discards`
		- When adding your drive to `/etc/crypttab` add `discard` next to `luks`, like this:
			```
			voidvm   /dev/sda1   /boot/volume.key   luks,discard
			```
	- After going through the base installation, edit `/etc/lvm/lvm.conf`. Uncomment `issue_discards = 0` (meaning delete the # at the beginning of that line), and set it to 1: `issue_discards = 1`
	- To verify that TRIM has been configured properly do `dmsetup table /dev/mapper/voidvm --showkeys` and look for `allow_discards` in the output. Swap `voidvm` with whatever your hostname is
- To determine how much swap space to use: https://docs.voidlinux.org/installation/live-images/partitions.html#swap-partitions
- To determine which mirror to use: https://xmirror.voidlinux.org/

## Notes for the install media:
- If your system uses legacy BIOS (MKR): https://docs.voidlinux.org/installation/live-images/partitions.html#bios-system-notes
- If your system uses UEFI: https://docs.voidlinux.org/installation/live-images/partitions.html#uefi-system-notes
- If you're installing onto an SSD: https://docs.voidlinux.org/config/ssd.html


# Post-install
1. Update packages and set mirror
	1. Login as root (you set the password during install)
	2. Update packages with `xbps-install -Su`
		- If you get a transient resolver failure run this: `dhcpcd`, you might have to do it twice
	3. Set mirror with:
		```
		xbps-install xmirror
		xmirror
		xbps-install -Su
		```
2. Add non-root user if you haven't already
	- You need to do this if you used the full disk encryption install
	- You do not need to do this if you used the install media
		```
		useradd -m <username>
		passwd <username>
		```
3. Add user to groups and make sudoer
	1. Add user to groups: `usermod -aG users,audio,video,cdrom,input,wheel,plugdev,lp,scanner,dialout,storage <username>`
	2. If you want you can verify user is in groups: `groups <username>`
	3. Edit sudo file so wheel group is a sudoer
		1. `visudo`
		2. Uncomment `%wheel ALL=(ALL) ALL` (meaning delete the # at the beginning of that line)
4. Post-install script
	1. Download the script:
		```
		su <username>
		cd
		sudo xbps-install -S curl
		curl -o auto-void.sh https://raw.githubusercontent.com/finder-1/void-install/refs/heads/main/auto-void.sh
		```
	By default this script:
	- Installs Sway window manager
	- Installs kitty (terminal), fuzzel (application search), Waybar (taskbar), neovim (text editor), grim (screenshot tool), yazi (cli file manager), pcmanfm-qt (gui file manager), yt-dlp (media downloader), ffmpeg (multimedia handler), VLC (media player), OBS (video recording), Librewolf (web browser), LibreOffice suite (word processing, spreadsheats, slideshows) and many more miscellaneous packages 
	- Downloads dotfiles (configuration files)
	- Installs GPU drivers
	- Installs CPU microcode updates
	- Installs fonts
	- Sets up Pulseaudio, chrony, polkitd, rtkit, seatd, dbus, socklog, ACPI, NetworkManager
	- Removes unused TTYs
	and more.
	
	Non-default options include:
	- Obsidian Flatpak (note-taking, productivity, writing)
	- Tauon Flatpak (music player)
	- Gaming (installs everything needed for gaming on Void)
	- Speyll's dotfiles
	
	You should go through the script and decide what you want to include for your own system.
	
	Once ready, run the following. Remember to **not** run the script as root: 
	```
	chmod +x ~/auto-void.sh
	~/auto-void.sh
	```
	After running the script run:
	```
	sudo usermod -aG _seatd,socklog,network $USER
	rm ~/auto-void.sh
	sudo reboot
	```
5. Recommended post-script configurations:
	- Boot straight into Sway rather than TTY:
		- Edit `/etc/sv/agetty-tty1/conf`
		- Find where it says `GETTY_ARGS="--noclear"` and add `-a username`
			```
			GETTY_ARGS="--noclear -a username"
			```
	- Fix audio on YouTube always being low:
		- Install [Violentmonkey](https://addons.mozilla.org/firefox/addon/violentmonkey/)
		- Create a new userscript and paste this: https://pastes.dev/fVL6SIyxQj
	- Obsidian theme:
		- Change the accent color in Obsidian to `146 R 131 G 116 B`. This is the same color as the window manager, taskbar, and terminal. The setting can be found in Appearance on the Obsidian app. You can also add this to icons if you use the Iconize plugin. You could also try `251 R 241 G 199 B`
	- Flatpak application permissions:
	  - In Flatseal (installed by default) give LibreWolf and Obsidian permissions to all files, along with any other applications you install and think need those permissions
