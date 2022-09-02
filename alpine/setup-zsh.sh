#!/usr/bin/env bash
set -ex

apk add zsh

ohmyzsh_path=/etc/oh-my-zsh
# oh-my-zsh
git clone https://github.com/ohmyzsh/ohmyzsh.git "$ohmyzsh_path" &&
    mkdir -p /etc/skel &&
    cp "$ohmyzsh_path/templates/zshrc.zsh-template" /etc/skel/.zshrc &&
    sed -ie "s|\$HOME/\.oh-my-zsh|$ohmyzsh_path|g" /etc/skel/.zshrc &&
    sed -ie "s|^ZSH_THEME=.*$|ZSH_THEME=\"ys\"|" /etc/skel/.zshrc

# zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-autosuggestions.git \
    $ohmyzsh_path/custom/plugins/zsh-autosuggestions &&
    sed -ie "s|^plugins=(|plugins=(zsh-autosuggestions |" /etc/skel/.zshrc

# zsh-syntax-highlighting
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git \
    $ohmyzsh_path/custom/plugins/zsh-syntax-highlighting &&
    sed -ie "s|^plugins=(|plugins=(zsh-syntax-highlighting |" /etc/skel/.zshrc

unset ohmyzsh_path
