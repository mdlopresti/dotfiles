function lpass {
  wsl lpass $args
}
function lpass-add-ssh($KeyName) {
  wsl printf "Private Key:$(cat .ssh/$KeyName)\nPublic Key:$(cat .ssh/$KeyName.pub)" `| lpass add --sync=now --non-interactive --note-type=ssh-key $KeyName
}

oh-my-posh init pwsh --config ($env:USERPROFILE + "\.oh-my-posh.omp.json") | Invoke-Expression