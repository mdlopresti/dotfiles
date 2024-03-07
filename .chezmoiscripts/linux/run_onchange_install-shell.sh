#!/bin/bash

wget https://github.com/JanDeDobbeleer/oh-my-posh/releases/latest/download/posh-linux-amd64 -O ~/oh-my-posh
chmod +x ~/oh-my-posh

echo 'eval "$(~/oh-my-posh --init --shell bash --config ~/.oh-my-posh.omp.json)"' >> ~/.bashrc
