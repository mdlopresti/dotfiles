#!/bin/sh
curl -sfL https://git.io/chezmoi | sudo sh -s -- -b /usr/local/bin
chezmoi init --apply --verbose https://github.com/mdlopresti/dotfiles.git
