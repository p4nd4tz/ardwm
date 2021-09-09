#!/bin/sh

id=$(id -u)
if [ $id == 0 ]; then
  dialog --infobox "This script should not be run as root,\ncause you could ruin your system.\nAnd you do not want to install your base system again " 7 50
  exit 1
fi 

while getopts "h:p" o; do 
	case "${o}" in
	h) printf "Optional arguments for custom use:\\n -p: Dependencies and programs csv (local file or url)\\n -h: Show this message\\n" && exit 1 ;;
	p) progsfile=${OPTARG} ;;
	*) printf "Invalid option: -%s\\n" "$OPTARG" && exit 1 ;;
esac done

[ -z "$progsfile" ] && progsfile="https://raw.githubusercontent.com/riceDwm/master/progs.csv"


## Welcome user
uname=$(whoami)

welcome(){ \
  # printf "%s" "WELCOME $uname"
  figlet "welcome $uname"
}

welcomemsg() { \
	dialog --title "Welcome!" --msgbox "Welcome $uname !\\n\\nThis script will automatically install DWM with my config files which I use as my main machine." 10 60

	dialog --colors --title "Important Note!" --yes-label "All ready!" --no-label "Exit..." --yesno "\nBe sure you have an active internet connection ." 8 70 || { clear; exit 1; }
}

## display pre installation message
preinstallmsg() { \
	dialog --title "Last Remainder!" --yes-label "Let's go!" --no-label "Nope, thank you!" --yesno "\nStart the installation process by pressing <Let's go!> and the system will begin installation!\n\n OR \n\n you can cancell it" 13 60 || { clear; exit 1; }
}

## in case of any interruption 
error() { printf "%s\n" "$1" >&2; exit 1; }

cpyconfig() { #copying config at right places
	dialog --info "copying .xprofile .xinitrc and .zprofile" 2 50
	cp "$HOME/.config/x/.xprofile" "$HOME/.config/.xprofile"
	cp "$HOME/.config/x/.xinitrc" "$HOME/.config/.xinitrc"
	cp "$HOME/.config/zsh/.zprofile" "$HOME/.zprofile"
}

installdwm() { #installing dwm
	dialog --info "installing dwm as your window manager && \ndmenu as application launcher" 4 50
	cd "$HOME/.config/suckless/dwm-6.2/"
	sudo make clean install >/dev/null 2>&1
	cd "$HOME/.config/suckless/dmenu-5.0/"
	sudo make clean install >/dev/null 2>&1
	cd "$HOME"
	cp -rf "ardwm/bin" "$HOME/.local/"
	ln -s "$HOME/.local/bin" "$HOME/bin"
}

putgitrepo() { # Downloads a gitrepo $1 and places the files in $2 only overwriting conflicts
	dialog --infobox "Downloading and installing config files..." 4 60
	[ -d 'dotfiles' ] && dialog --infobox "backing up your dotfiles directory" &&	mv -f dotfiles dotfiles.bak
	git clone https://github.com/Abhishek416/dotfiles.git -b stable
	[ ! -d "$HOME/.config" ] && mkdir -p "$HOME/.config"
	cp -rf 'dotfiles/*' '$HOME/.config/'
}

maininstall() { # Installs all needed programs from main repo.
	dialog --title "Installaing" --infobox "Installing \`$1\` ($n of $total). $1" 5 70
	sudo pacman --noconfirm --needed -S "$1" >/dev/null 2>&1
	}

installationloop(){ \
	([ -f "$progsfile" ] && cp "$progsfile" /tmp/progs.csv) || curl -Ls "$progsfile" > /tmp/progs.csv
	total=$(wc -l < /tmp/progs.csv)

	while IFS=, read -r program; do
		n=$((n+1))
		maininstall "$program" 
	done < /tmp/progs.csv ;
}

finalize(){ \
	dialog --infobox "Preparing welcome message..." 4 50
	dialog --title "All done!" --msgbox "Congrats! Provided there were no hidden errors, the script completed successfully and all the programs and configuration files should be in place.\\n\\nTo run the new graphical environment, log out and log back in as your new user, then run the command \"startx\" to start the graphical environment (it will start automatically in tty1).\\n\\n" 12 80
}

#########################
### THE ACTUAL SCRIPT ###
#########################

# welcome function
welcomemsg || error "User existed"


# Last chance for user to back out before install.
preinstallmsg || error "user exited."

for x in curl base-devel git ntp zsh; do
	dialog --title "installing" --infobox "installing \`$x\` which is required to install and configure other programs." 5 70
	# installpkg "$x"
  sudo pacman --noconfim --needed -S "$x" >/dev/null 2>&1 ;
done

# main installation loop 
installationloop

# Install dotfiles in user's home directory
putgitrepo || echo "user exited. "
rm -f "/home/$uname/.config/README.md" "/home/$uname/.config/desktop.png" "/home/$uname/.config/.git/" "/home/$uname/.config/nitrogen"
cd "/home/$uname/"

# copying xprofile and zprofile 
cpyconfig

# installing dwm && dmenu
installdwm

# make zsh as default shell
chsh -s /bin/zsh "$name" >/dev/null 2>&1
sudo -u "$name" mkdir -p "/home/$uname/.cache/zsh/"

# unmute alsa 
#
#

# Last message! Install complete!
finalize
clear

