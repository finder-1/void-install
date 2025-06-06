# void-install
A Void Linux with Sway window manager install guide and post-install script.


I made this guide as a way to install Void Linux easily on my machines. It is not a just-works solution. You will need to do some configuring yourself and still need to know your way around setting up a bare-bones Linux desktop from scratch.



1. full disk encryption + partitioning 
    - https://docs.voidlinux.org/installation/guides/fde.html#full-disk-encryption
    - ensure disk has GPT disklabel when you run `fdisk -l <drive>`
    - give 300M size for EFI partition
    - when opening the LUKS device add --allow-discards: 'cryptsetup luksOpen --allow-discards /dev/sdaX luks'
    - when doing cryptsetup do it for the non-EFI partition, not the entire drive
    - when editing the GRUB config, do not erase what already exists in `GRUB_CMDLINE_LINUX_DEFAULT=`. instead, put a space between each entry. also add "rd.luks.allow-discards"
    - when adding your drive to /etc/crypttab, add "discard" next to luks, like this : luks,discard
    2. decide how much swap space to use
        https://docs.voidlinux.org/installation/live-images/partitions.html
    3. decide which mirror to use
        https://xmirror.voidlinux.org/

2. enable trimming on SSD
    https://docs.voidlinux.org/config/ssd.html
    - everything besides enabling trim when you change the logical volume should already be done.
    - to enable trim when changing the logical volume size edit `/etc/lvm/lvm.conf`, uncomment the issue_discards option, and set it to 1:
`issue_discards=1`
    - then verify that TRIM has been configured correctly by doing `dmsetup table /dev/mapper/crypt_dev --showkeys` and look for `allow_discards` in the output. swap "crypt_dev" with whatever your hostname is (e.g. void-pc)

4. update packages
`dhcpcd` <-- (if you get a transient resolver failure it's probably because you didn't run this.)
`sudo xbps-install -Su`

5. add non-root user
    1. create user and password, and login
```
useradd -m <username>
passwd <username>
```

    2. add user to groups, including wheel
`usermod -aG users,audio,video,cdrom,input,wheel,plugdev,lp,scanner,dialout,storage <username>`
	- if you want you can verify user is in groups
	`groups <username>`
    3. edit sudo file so wheel group is a sudoer
        `visudo`
        uncomment `%wheel ALL=(ALL) ALL`


5. post-install script
```
su <username>
cd ~
sudo xbps-install -S curl
curl -o auto-void.sh https://raw.githubusercontent.com/finder-1/void-install/refs/heads/main/auto-void.sh
```

by default this script:
- installs Sway window manager
- installs kitty (terminal), fuzzel (application search), Waybar (taskbar), neovim (text editor), grim (screenshot tool), yazi (cli file manager), pcmanfm-qt (gui file manager), yt-dlp (media downloader), ffmpeg (multimedia handler), VLC (media player), OBS (video recording), Librewolf (web browser), LibreOffice suite (word processing, spreadsheats, slideshows) and many more miscellaneous packages 
- downloads dotfiles (configuration files)
- installs GPU drivers
- installs CPU microcode updates
- installs fonts
- sets up PipeWire, bluetooth autostart, chrony, polkitd, rtkit, seatd, dbus, socklog, ACPI, NetworkManager
- removes unused TTYs
   
non-default options include:
- Obsidian (note-taking, productivity, writing)
- Tauon (music player)
- Gaming (installs everything needed for gaming on Void)
- Speyll's dotfiles

it is recommended that you go through the script and decide what you want to include for your own system. Once ready, run the following. Remember to not run the script as root: 
```
chmod +x ~/auto-void.sh
~/auto-void.sh
```

after running the script:
 ```
usermod -aG _seatd,socklog,network $USER
rm ~/auto-void.sh
sudo reboot
 ```


recommended post-script configurations:
- Obsidian theme
	- change the accent color in Obsidian to `146 R 131 G 116 B`. this is the same color as the window manager, taskbar, and terminal. you could also try `251 R 241 G 199 B`. the setting can be found in Appearance on the Obsidian app
- Flatpak application permissions
  -in Flatseal (installed by default) give LibreWolf and Obsidian permissions to all files, along with any other applications you install and think need those permissions
