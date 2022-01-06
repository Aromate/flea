#!/bin/bash

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
FLEA_DIR=$(cd $SCRIPT_DIR/../ && pwd)

# Import env set config lib
. $FLEA_DIR/lib/env.sh

# Define sdk,march,board,profile_march to config the board env,and check it
check_var SCRIPT_NAME || exit 1
set_var CHOST && check_var CHOST
set_var MARCH && check_var MARCH
set_var BOARD && check_var BOARD
set_var PROFILE_MARCH && check_var PROFILE_MARCH

# config rootfs,rootfs should have default varual
set_var BUILD_DIR
if [[ $BUILD_DIR != "" ]]; then
  ROOTFS=$BUILD_DIR/flea/build/${BOARD}
else
  ROOTFS=${FLEA_DIR}/build/${BOARD}
fi

PROFILE_MARCH=${ROOTFS}/var/db/repos/gentoo/profiles/${PROFILE_MARCH}
# PROFILE_MARCH=../../var/db/repos/gentoo/profiles/${PROFILE_MARCH}
PROFILES=${FLEA_DIR}/profiles

# check environment,make sure git, sudo access.
check_env

# if config set,run the special scripts.
set_var SCRIPT
if [[ $SCRIPT != "" ]]; then
  . $FLEA_DIR/scripts/${SCRIPT}.sh
fi

. $FLEA_DIR/scripts/board.sh

# run like clean and build board scripts
. $FLEA_DIR/scripts/${SCRIPT_NAME}.sh $@
