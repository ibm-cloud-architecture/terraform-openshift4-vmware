#!/bin/bash
user_private_key=$1
user=$2
private_key_file=$HOME/.ssh/id_rsa

if [ "$user_private_key" != "None" ] ; then
  if [ ! -f ${HOME}/.ssh/id_rsa ]; then
    mkdir -p ~/.ssh
    chmod 700 ~/.ssh
    touch ${HOME}/.ssh/id_rsa
  fi
  echo "$user_private_key" > $private_key_file
  chmod 400 $private_key_file

  eval "$(ssh-agent)"
  ssh-add $private_key_file

  if [[ $? -ne 0 ]]; then
    echo "FAILED to add private ssh key"
    exit 1
  else
    echo "SUCCESFULLY added private ssh key"
	fi
fi
