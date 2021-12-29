#!/bin/bash

# import some lib scripts
. $FLEA_DIR/lib/crossdev.sh
. $FLEA_DIR/lib/config.sh

# Init crossdev
echo "Init/Update crossdev tools..."
init_crossdev

# Create sdk by crossdev
echo "Update/Create cross sdk..."
create_sdk

# Create rootfs && install some packages
echo "Init rootfs..."
create_rootfs

# Portage config,deployment overlays
config_portage
