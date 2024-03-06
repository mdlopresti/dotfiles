# mdlopresti dotfiles

This is a revamp of my dotfiles from scratch, and it is open sources.  My old dotfiles were a hand made symlink based repo that I wasn't 100% cofident didn't have anything secret in it.  This new version is [chezmoi](https://www.chezmoi.io/) based which means anything secret I can put into my perferred password manager and kept out of source control.  

Currently this is a bare bones system but I plan to add to it overtime to include better seperation between work and personal using the [template](https://www.chezmoi.io/user-guide/templating/) system. 

## Install strings

#### Linux
```shell
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply
```
#### Windows
```powershell
winget install twpayne.chezmoi
# restart shell
chezmoi init --apply --verbose https://github.com/mdlopresti/dotfiles.git
```