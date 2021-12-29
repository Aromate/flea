#!/bin/bash

#################################################
#              About portage config             #
#################################################

create_rootfs() {
  # create file system
  mkdir -p $ROOTFS/{bin,dev,etc,lib,lib64,mnt,proc,root,sbin,sys,tmp,usr/lib,usr/lib64}

  # create dev node
  cp -f --archive /dev/{null,console,tty} $ROOTFS/dev 2>/dev/null 1>&2
}

_clone() {
  local repository=$1
  local name=$(echo $1 | rev | cut -d "/" -f 1 | rev | cut -d "." -f 1)
  if [[ ! -d $ROOTFS/var/db/repos/$name ]]; then
    git clone $repository $ROOTFS/var/db/repos/$name
  fi
}

_pull() {
  local name=$(echo $1 | rev | cut -d "/" -f 1 | rev | cut -d "." -f 1)
  local path=$(pwd)
  cd $ROOTFS/var/db/repos/$name
    
  git pull
  cd $path
}

update_overlay() {
  # only update $curio
  _pull $curio
}

    
_makeconf() {
  cat >$ROOTFS/etc/portage/make.conf <<EOF
  # config 
  MAKEOPTS="-j$(nproc)"
  COMMON_FLAGS="-O2 -pipe -march=$MARCH"
  CFLAGS="\${COMMON_FLAGS}"
  CXXFLAGS="\${COMMON_FLAGS}"
  FCFLAGS="\${COMMON_FLAGS}"
  FFLAGS="\${COMMON_FLAGS}"
  CBUILD="$SDK"

  # bindist flag
  # Gentoo overlay is different
  PORTDIR="/var/db/repos/gentoo"
  DISTDIR="/var/cache/distfiles"
  PKGDIR="$ROOTFS/var/cache/binpkgs"

  # config portage tmp dir
  # PORTAGE_TMPDIR="$ROOTFS/tmp"
  PORTAGE_TMPDIR="/tmp"
EOF
}

_repos() {
  local name=$1
  cat >$ROOTFS/etc/portage/repos.conf/$name.conf <<EOF
  [$name]
  location = /var/db/repos/$name
EOF
}

# _profiles config the /etc/portage
_profiles() {
  # make.conf
  _makeconf
  # ln make.profile, important
  ln -sf $PROFILE_MARCH $ROOTFS/etc/portage/make.profile
  # config package.use package.license
  cp -r $PROFILES/package.* $ROOTFS/etc/portage/
}

# Config portage,about overlay deployment,and overlay config
config_portage() {

  # create portage config tree
  mkdir -p $ROOTFS/etc/portage/repos.conf

  # deployment overlay: gentoo, curio, board
  if [[ ! -d $ROOTFS/var/db/repos ]]; then
    mkdir -p $ROOTFS/var/db/repos
  fi
  if [[ ! -L $ROOTFS/var/db/repos/gentoo ]]; then
    rm -rf $ROOTFS/var/db/repos/gentoo # clean
    ln -sf /var/db/repos/gentoo $ROOTFS/var/db/repos/gentoo
  fi
  _repos gentoo
  _repos curio
  _repos board

  # Config overlays configs,and config portage profiles
  _profiles # config profiles like make.conf,make.profiles,package.*

  # set the attrs,make sure the portage system can read the ebuilds
  chown -R portage:portage $ROOTFS/var/db/repos
  chmod +x -R $ROOTFS/var/db/repos
}
