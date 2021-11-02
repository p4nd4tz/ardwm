#!/bin/sh

uname=$(whoami)

if [ "$(id -u)" = 0 ]; then
  echo "##################################################################"
  echo "This script MUST NOT be run as root user."
  echo "cause you could ruin you system."
  echo "And you do not want to install your base system again"
  echo "##################################################################"
  exit 1
fi 

error() { \
    clear; printf "ERROR:\\n%s\\n" "$1" >&2; exit 1;
}

echo "################################################################"
echo "## Syncing the repos and installing 'dialog' if not installed ##"
echo "################################################################"
sudo pacman --noconfirm --needed -Sy dialog || error "Error syncing the repos."

welcome() { \
	dialog --title "Welcome!" --msgbox "Welcome $uname !\\n\\nThis script will automatically install DWM with my config files which I use on my main machine." 10 60

	dialog --title "Important Note!" --yes-label "All ready!" --no-label "Exit..." --yesno "\nBe sure you have an active internet connection ." 8 70 
}

welcome || error "User choose to exit"

## display pre installation message
preinstallmsg() { \
	dialog --title "Last Remainder!" --yes-label "Let's go!" --no-label "Nope, thank you!" --yesno "\nStart the installation process by pressing <Let's go!> and the system will begin installation!\n\n OR \n\n you can cancell it" 13 60 || { clear; exit 1; }
}

clonerepo() { \
  echo "################################################################"
  echo "## cloning dotfiles && You will get your old ~/.config in ~/.config.bak"
  echo "################################################################"

  [ -d 'dotfiles' ] && echo "backing up you dotfiles directory" && mv -f dotfiles dotfiles.bak
  git clone https://github.com/abhishek416/dotfiles.git -b stable 

  for x in bspwm i3 nitrogen nvim-coc nvim.lua sxhkd xmobar xmonad desktop.png README.md .git; do
    rm -rf 'dotfiles/$x' >/dev/null 2>&1;
  done
  
  if [ -d "$HOME/.config" ]; then
    mv $HOME/.config $HOME/.config.bak
  fi

  mv dotfiles $HOME/.config

  if [ ! -d 'fonts' ]; then
    echo "fonts directory not found."
    echo "Please download OR copy fonts from my ardwm repo"
    echo "OR you won't see your bar icons"
  else
    mv -f 'fonts' '$HOME/.local/share/'
  fi
}


installdwm() { #installing dwm
	dialog --info "installing dwm as your window manager && \ndmenu as application launcher" 4 50
	cd "$HOME/.config/suckless/dwm-6.2/"
	sudo make clean install >/dev/null 2>&1
	cd "$HOME/.config/suckless/dmenu-5.0/"
	sudo make clean install >/dev/null 2>&1
	cd "$HOME"
}

managebar() { \ #managing bar
  dialog --info "configuring your bar" 4 50
  cd "$HOME"
  if [ ! -d '$HOME/.local/bin' ]; then
    mkdir $HOME/.local/bin
    cp -rf "$HOME/.config/bin/dwm_status" "$HOME/.local/bin/"
    rm -rf "$HOME/.config/bin"
  else if [ -d '$HOME/.local/bin' ]; then
    cp -rf "$HOME/.config/bin/dwm_status" "$HOME/.local/bin/"
    rm -rf "$HOME/.config/bin"
  fi
  # cp -rf "$HOME/.config/bin" 
}

cpyconfig() { #placing config at right places
	dialog --info "linking bash_profile .xinitrc and .zprofile" 2 50
  ln -s "$HOME/.config/bash/bash_profile" "$HOME/.bash_profile"
	ln -s "$HOME/.config/x/xinitrc" "$HOME/.xinitrc"
	ln -s "$HOME/.config/zsh/zprofile" "$HOME/.zprofile"
  ln -s "$HOME/.local/bin" "$HOME/bin"
}

unmutealsa() { \
  amixer sset Master unmute 
  amixer sset Speaker unmute
  amixer sset Headphone unmute
}

finalize(){ \
	dialog --infobox "Preparing welcome message..." 4 50
	dialog --title "All done!" --msgbox "Congrats! Provided there were no hidden errors, the script completed successfully and all the programs and configuration files should be in place.\\n\\nTo run the new graphical environment, log out and log back in as your new user, then run the command \"startx\" to start the graphical environment (it will start automatically in tty1).\\n\\n" 12 80
}

#########################
### THE ACTUAL SCRIPT ###
#########################

for x in curl base-devel git zsh; do
	dialog --title "installing" --infobox "installing \`$x\` which is required to install and configure other programs." 5 70
  sudo pacman --noconfim --needed -S "$x" >/dev/null 2>&1 ;
done

clonerepo || error "User Exited"

installdwm || error "Error While Installing dwm"

managebar 
cpyconfig

# make zsh as default shell
chsh -s /bin/zsh "$name" >/dev/null 2>&1
sudo -u "$name" mkdir -p "/home/$uname/.cache/zsh/"

# unmute alsa 
unmutealsa || error "error while unmuting alsa"

# Last message! Install complete!
finalize
clear

