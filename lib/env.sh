#!/bin/bash

# set_var declare the env, if not define will not set.
set_var() {
  # The ${!var} get real var
  # https://www.gnu.org/software/bash/manual/html_node/Shell-Parameter-Expansion.html
  if [[ ${!1} == "" ]]; then
    local var=$(cat $FLEA_DIR/sdk_config | grep -w $1 | cut -d '=' -f 2)
    if [[ $(cat $FLEA_DIR/sdk_config |grep -v "#" | grep $1) == "" ]]; then
      return
    fi
    if [[ $var != "" ]]; then
      declare -g ${1}="$var"
    fi
  fi
}

check_var() {
  if [[ ${!1} == "" ]]; then
    echo "Please set/init $1 var..."
    exit 1
  fi
}

# check sdk env
check_env() {
  # check sudo env
  [[ $(which sudo) == "" ]] && (echo "Please install sudo...")

  # check sudo can access
  timeout 2 sudo id 1>/dev/null 2>&1 || (echo "Please add $USER to sudoer..." && exit 1)

  # auto install git in sdk...
  if [[ $(which git) == "" ]]; then
    echo "Install git tool..."
    sudo emerge -a dev-cvs/git || exit 1
  fi
}
