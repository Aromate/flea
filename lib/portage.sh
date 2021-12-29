#!/bin/bash

_equery() {
  CHOST="$SDK" ROOT=$ROOTFS SYSROOT=$ROOTFS PORTAGE_CONFIGROOT=$ROOTFS \
    equery "$@"
}

init_board() {
  # CHOST="$SDK" ROOT=$ROOTFS SYSROOT=$ROOTFS PORTAGE_CONFIGROOT=$ROOTFS \
    emerge --root-deps --root=$ROOTFS --config-root=$ROOTFS $BOARD || exit 1
}

_emerge() {
  # CHOST="$SDK" ROOT=$ROOTFS SYSROOT=$ROOTFS PORTAGE_CONFIGROOT=$ROOTFS \
    emerge --root-deps --root=$ROOTFS --config-root=$ROOTFS $@ || exit 1
}

update_selected() {
  # install ROOTFS @selected deps
  # CHOST="$SDK" ROOT=$ROOTFS SYSROOT=$ROOTFS PORTAGE_CONFIGROOT=$ROOTFS \
    emerge --root-deps --root=$ROOTFS --config-root=$ROOTFS -avuDN @selected || exit 1
}
