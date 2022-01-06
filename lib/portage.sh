#!/bin/bash

_equery() {
  CHOST="$CHOST" CBUILD="x86_64-pc-linux-gnu" ROOT=$ROOTFS SYSROOT=$ROOTFS PORTAGE_CONFIGROOT=$ROOTFS \
    equery "$@"
}

_portageq () {
  CHOST="$CHOST" CBUILD="x86_64-pc-linux-gnu" ROOT=$ROOTFS SYSROOT=$ROOTFS PORTAGE_CONFIGROOT=$ROOTFS \
    portageq "$@"
}

init_board() {
  CHOST="$CHOST" CBUILD="x86_64-pc-linux-gnu" ROOT=$ROOTFS SYSROOT=$ROOTFS PORTAGE_CONFIGROOT=$ROOTFS \
    emerge --root-deps $BOARD || exit 1
}

_emerge() {
  CHOST="$CHOST" CBUILD="x86_64-pc-linux-gnu" ROOT=$ROOTFS SYSROOT=$ROOTFS PORTAGE_CONFIGROOT=$ROOTFS \
    emerge --root-deps $@ || exit 1
}

update_selected() {
  # install ROOTFS @selected deps
  CHOST="$CHOST" CBUILD="x86_64-pc-linux-gnu" ROOT=$ROOTFS SYSROOT=$ROOTFS PORTAGE_CONFIGROOT=$ROOTFS \
    emerge --root-deps --root=$ROOTFS --config-root=$ROOTFS -avuDN @selected || exit 1
}
