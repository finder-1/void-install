#!/bin/sh
# Void Linux Post-Installation Script for Wayland
# Author: Speyll, forked by finder-1
# Last-update: 06-18-2025

# Enable debugging output and exit on error
set -x

# Add multilib and nonfree repositories
# sudo xbps-install -Sy void-repo-nonfree

# Update package lists and upgrade existing packages
sudo xbps-install -Syu

# Install GPU drivers
install_gpu_driver() {
  gpu_driver=""
  case "$(lspci | grep -E 'VGA|3D')" in
    *Intel*) gpu_driver="mesa-dri intel-video-accel vulkan-loader mesa-vulkan-intel" ;;
    *AMD*)   gpu_driver="mesa-dri mesa-vaapi mesa-vdpau vulkan-loader mesa-vulkan-radeon" ;;
    *NVIDIA*)gpu_driver="mesa-dri nvidia nvidia-libs-32bit" ;;
  esac
  for pkg in $gpu_driver; do
    [ -n "$pkg" ] && sudo xbps-install -y "$pkg"
  done
}

install_gpu_driver

# Install CPU microcode updates
if lspci | grep -q 'Intel'; then
  sudo xbps-install -y intel-ucode
  sudo xbps-reconfigure -f linux-$(uname -r)
fi

# Install other packages
install_core_packages() {
  for pkg in sway seatd socklog git tmux wayland dbus dbus-glib polkit polkit-gnome chrony \
             xdg-utils xdg-desktop-portal-gtk xdg-desktop-portal-gnome xdg-desktop-portal-wlr xdg-desktop-portal \
             pulseaudio pavucontrol rtkit wlr-randr xdg-user-dirs \
             noto-fonts-emoji noto-fonts-cjk-sans noto-fonts-ttf nerd-fonts-symbols-ttf \
             grim slurp wl-clipboard cliphist wvkbd \
             swayimg imv swaybg mpv mpvpaper ffmpeg yt-dlp \
             fnott libnotify \
             yazi unzip p7zip unrar xz thunar ffmpegthumbnailer webp-pixbuf-loader tumbler lxqt-archiver gvfs-smb gvfs-afc gvfs-mtp udisks2 \
             flavours breeze-gtk breeze-snow-cursor-theme breeze-icons \
             qt5-wayland bluez \
	     htop base-devel socklog-void swaylock vlc obs libreoffice \
	     labwc neovim kitty Waybar wlsunset fuzzel brightnessctl bash-completion; do
    sudo xbps-install -y "$pkg" || echo "Failed to install $pkg"
  done
}

install_networking_packages() {
  for pkg in fuse-sshfs lynx rsync wireguard; do
    sudo xbps-install -y "$pkg"
  done
}

install_flatpak_packages() {
 sudo xbps-install -y flatpak
 flatpak remote-add --if-not-exists --user flathub https://dl.flathub.org/repo/flathub.flatpakrepo
 flatpak install flathub io.gitlab.librewolf-community
 flatpak install flathub com.github.tchx84.Flatseal
# flatpak install flathub com.github.taiko2k.tauonmb
# flatpak install flathub md.obsidian.Obsidian
}

install_flatpak_gaming() {
  flatpak install flathub com.usebottles.bottles
  flatpak install flathub org.freedesktop.Platform.VulkanLayer.MangoHud
  flatpak install flathub org.freedesktop.Platform.VulkanLayer.gamescope
  flatpak install flathub com.valvesoftware.Steam.CompatibilityTool.Proton-GE
  flatpak install flathub com.obsproject.Studio.Plugin.OBSVkCapture
  flatpak install flathub org.freedesktop.Platform.VulkanLayer.OBSVkCapture
}

install_gaming_packages() {
  for pkg in void-repo-multilib-nonfree \
             libgcc-32bit libstdc++-32bit libdrm-32bit libglvnd-32bit wine wine-mono gamemode MangoHud gamescope; do
    sudo xbps-install -y "$pkg"
  done
  sudo usermod -aG gamemode $USER 
}

# !IMPORTANT! here you can select what gets installed and what not by commenting
install_core_packages
install_networking_packages
install_flatpak_packages
#install_flatpak_gaming
#install_gaming_packages

# Make audio work on Librewolf
sudo flatpak override --device=all --filesystem=home io.gitlab.librewolf-community

# Create common user directories (might want to remove the ones you don't want)
xdg-user-dirs-update
#rmdir $HOME/Templates
#rmdir $HOME/Public
#rmdir $HOME/Desktop


sudo ln -s /etc/sv/bluetoothd /var/service/

# Set up chrony
sudo ln -s /etc/sv/chronyd /var/service/

# Set up polkitd
sudo ln -s /etc/sv/polkitd /var/service/

# Set up rtkit
sudo ln -s /etc/sv/rtkit /var/service/

# Set up seatd
sudo ln -s /etc/sv/seatd /var/service

# Set up dbus
sudo ln -s /etc/sv/dbus /var/service

# Set up socklog
ln -s /etc/sv/socklog-unix/ /var/service
ln -s /etc/sv/nanoklogd/ /var/service

# Remove unused services (TTYs)
for tty in 3 4 5 6; do
  sudo rm -rf /var/service/agetty-tty"$tty"
done

# Move xbps-cache to home directory
sudo mv /var/cache/xbps /home/$USER/xbps-cache
sudo ln -s /home/$USER/xbps-cache /var/cache/xbps

# Set up ACPI
sudo ln -s /etc/sv/acpid/ /var/service/
sudo sv enable acpid
sudo sv start acpid

# Improve font rendering
for conf in 11-lcdfilter-default.conf 10-sub-pixel-rgb.conf 10-hinting-slight.conf; do
  sudo ln -s /etc/fonts/conf.avail/"$conf" /etc/fonts/conf.d
done

# Set up NetworkManager
sudo xbps-install -Sy NetworkManager dbus
if sudo sv status wpa_supplicant >/dev/null 2>&1; then
  sudo sv stop wpa_supplicant
fi

sudo rm -rf /var/services/wpa_supplicant 2>/dev/null
sudo ln -s /etc/sv/dbus /var/service
sudo ln -s /etc/sv/NetworkManager /var/service
sudo sv start NetworkManager

# Clone and set up Speyll's dotfiles
# git clone https://github.com/speyll/dotfiles "$HOME/dotfiles"
# cp -r "$HOME/dotfiles/."* "$HOME/"
# rm -rf "$HOME/dotfiles"

# Clone and set up jvscholz's kitty and nvim configs
# git clone --filter=blob:none --no-checkout https://github.com/jvscholz/dotfiles
# cd $HOME/dotfiles
# git sparse-checkout set --cone
# git checkout master
# git sparse-checkout set nvim
# mv -f $HOME/dotfiles/nvim $HOME/.config
# git sparse-checkout set kitty
# mv -f $HOME/dotfiles/kitty $HOME/.config
# cd $HOME

# Clone and set up my Sway and fuzzel configs
# git clone https://github.com/finder-1/dotfiles "$HOME/dotfiles" 
# sudo cp -r "$HOME/dotfiles/.* "$HOME/"
# rm -rf "$HOME/dotfiles"


# chmod -R +X "$HOME/.local/bin" "$HOME/.local/share/applications" "$HOME/.config/autostart/" # Adjust permissions
# ln -s "$HOME/.config/mimeapps.list" "$HOME/.local/share/applications/" # Create symbolic link for mimeapps.list
# dash "$HOME/.local/share/fonts/git-fonts.sh" # Run the font installation script
# dash "$HOME/.local/share/icons/git-cursors.sh" # Run the cursors installation script

# Add user to wheel group for sudo access
# echo "%sudo ALL=(ALL:ALL) NOPASSWD: /usr/bin/halt, /usr/bin/poweroff, /usr/bin/reboot, /usr/bin/shutdown, /usr/bin/zzz, /usr/bin/ZZZ" | sudo tee -a /etc/sudoers.d/wheel
