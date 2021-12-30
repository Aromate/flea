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

_makeconf() {
  local file=$ROOTFS/etc/portage/make.conf
  local pkgdir="$ROOTFS/var/cache/binpkgs"
  # clean space
  sed -i -r 's/[ ]+"/ "/g' $file
  # config COMMON_FLAGS's march
  sed -i -r 's/(-march)=([^ "]+)/\1='$MARCH'/g' $file
  # config cbuild
  sed -i -r 's/CBUILD.*/CBUILD="'$SDK'"/g' $file
  # config pkgdir
  sed -i -r 's,(PKGDIR=").*",\1'${pkgdir}'",g' $file
  # config makeopts
  local thread="-j$(nproc)"
  sed -i -r 's/(MAKEOPTS=".*?[ "]*)\-j[1-9]+/\1'${thread}'/g' $file
  if [[ $(grep -E 'MAKEOPTS=".*\-j[1-9]*' $file) == "" ]]; then
    sed -i -r 's/(MAKEOPTS=")/\1'${thread}' /g' $file
  fi
}

_repository() {
  local overlay=$1
  local overlay_type=$2
  local overlay_uri=$3
  # check repository exists
  if [[ $(eselect repository list -i | grep $overlay) == "" ]]; then
    if [[ -d /var/db/repos/$overlay ]]; then
      echo "Please check host system overlay,the $overlay's dir exists."
      exit 1
    fi
    eselect repository add $overlay $overlay_type $overlay_uri
  fi

  # add repository config to $ROOTFS/etc/portage/repos.conf
  if [[ ! -d /var/db/repos/$overlay ]]; then
    echo "Please check overlay $overlay's dir, in /var/db/repos..."
    exit 1
  fi
  if [[ ! -f $ROOTFS/etc/portage/repos.conf/$overlay.conf ]]; then
    cat >$ROOTFS/etc/portage/repos.conf/$overlay.conf <<EOF
[$overlay]
location = /var/db/repos/$overlay
EOF
  fi
}

_profiles() {
  if [[ ! -L $ROOTFS/etc/portage ]]; then
    rm -rf $ROOTFS/etc/portage
    # ln to /etc/portage
    if [[ ! -d $FLEA_DIR/profiles ]]; then
      echo "Please check flea status,flea's profiles is not exists."
      exit 1
    fi
    ln -sf $FLEA_DIR/profiles $ROOTFS/etc/portage
  fi

  # config /etc/portage/make.conf
  _makeconf

  # deployment overlay: gentoo, curio, board
  if [[ ! -d $ROOTFS/var/db/repos ]]; then
    mkdir -p $ROOTFS/var/db/repos
  fi

  # deploy gentoo overlay,gentoo is different
  # gentoo overlay can use ln make.profile to sure the overlay exists
  if [[ ! -L $ROOTFS/var/db/repos/gentoo ]]; then
    rm -rf $ROOTFS/var/db/repos/gentoo # clean
    if [[ ! -L $ROOTFS/var/db/repos/gentoo ]]; then
      ln -sf /var/db/repos/gentoo $ROOTFS/var/db/repos/gentoo
    fi

    if [[ ! -L $ROOTFS/etc/portage/make.profile ]]; then
      # ln make.profile, need $ROOTFS/var/db/repos/gentoo
      if [[ ! -d $PROFILE_MARCH ]]; then
        ln -sf $PROFILE_MARCH $ROOTFS/etc/portage/make.profile
      else
        echo $PROFILE_MARCH is not a dir,can not link make.profile,please check...
        exit 1
      fi
    fi
  fi

  # config the overlays
  # _repository gentoo
  _repository curio git https://github.com/ErGog/curio.git
  _repository board git https://github.com/ErGog/board.git
}

# Config portage,about overlay deployment,and overlay config
config_portage() {

  # Config overlays configs,and config portage profiles
  _profiles # config profiles like make.conf,make.profiles,package.*

  # set the attrs,make sure the portage system can read the ebuilds
  chown -R portage:portage $ROOTFS/var/db/repos
  chmod +x -R $ROOTFS/var/db/repos
}
