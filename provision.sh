#!/bin/bash
set -e

VAGRANT_USER_PASS=vagrant
VAGRANT_HOME=/home/vagrant

export ASDF_VERSION=v0.10.2
export NVM_VERSION=0.39.2

sudo dnf upgrade -y
sudo dnf group install -y "Fedora Workstation" "i3 desktop" "C Development Tools and Libraries" "Python Science"
sudo systemctl set-default graphical.target
#sudo systemctl disable lightdm.service
#sudo systemctl enable gdm.service
sudo dnf install -y git vim neovim zsh kitty wget podman podman-compose skopeo buildah python3-pip python3.8 \
    nodejs npm golang gnome-tweaks gnome-extensions-app alacarte origin-clients helm gparted sqlite \
    xset jq sysstat ripgrep

# Configure GITHUB client https://github.com/cli/cli"
sudo dnf config-manager --add-repo https://cli.github.com/packages/rpm/gh-cli.repo
sudo dnf install -y gh

# Install VSCode
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
sudo sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'
dnf check-update
sudo dnf install code -y

# Configure spanish keyboard layout for gnome
gsettings set org.gnome.desktop.input-sources sources "[('xkb', 'es')]"

# I3 window mannager setup
sudo dnf install -y i3status i3blocks wget dmenu rofi ulauncher i3lock xbacklight feh conky lxappearance arc-theme fontawesome-fonts \
    powerline powerline-fonts fira-code-fonts lxpolkit compton
pip install bumblebee-status # Bar mannager for i3
sudo timedatectl set-timezone Europe/Madrid

# Configure Neovim with vim-plug (https://github.com/junegunn/vim-plug)
sh -c 'curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'

# Install asdf and plugins
git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch ${ASDF_VERSION}
. $HOME/.asdf/asdf.sh
asdf plugin list all
ASDF_PLUGINS=(golang yq maven poetry kind helm)
for p in $ASDF_PLUGINS
do
    asdf plugin add $p
    asdf install $p latest
    asdf global $p latest
done

# Install custom dotfiles
cd ${HOME} && git clone https://github.com/cristiancl25/dotfiles
./dotfiles/install.sh

# Nvm and node install
export PROFILE=$HOME/.zshrc
#export NODE_VERSION=16.3.0
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v${NVM_VERSION}/install.sh | bash
# Install latest version of node
#nvm install node
#nvm use node

# Install Oh My ZSH and set as default shell
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
echo "$VAGRANT_USER_PASS" | chsh -s $(which zsh)

# Sets default plugins for oh my zsh
sed -i '/^plugins=/s/.*/plugins=(git asdf gh)/' ${HOME}/.zshrc

cat <<-EOFILE > "/sharedfs/vagrant_env.sh"
#!/bin/bash
export PATH=\${HOME}/.local/bin:\${PATH}

alias p=podman
alias pc=podman-compose
alias docker=podman
alias cr="clear && reset"
EOFILE
chmod +x /sharedfs/vagrant_env.sh

echo "source /sharedfs/vagrant_env.sh" >> ${VAGRANT_HOME}/.zshrc

sudo reboot
