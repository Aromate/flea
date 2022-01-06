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

_pkgconfig () {
  # bug:Can not found some library
  cat >$ROOTFS/bin/pkg-config <<EOF
#!/bin/bash

PKG_CONFIG_LIBDIR=$(printf '%s:' "${ROOTFS}"/usr/*/pkgconfig)
export PKG_CONFIG_LIBDIR

export PKG_CONFIG_SYSROOT_DIR="${ROOTFS}"

# Portage will get confused and try to "help" us by exporting this.
# Undo that logic.
unset PKG_CONFIG_PATH

# Use full path to bypass automated wrapper checks that block `pkg-config`.
# https://crbug.com/985180
exec /usr/bin/pkg-config "\$@"
EOF
chmod +x $ROOTFS/bin/pkg-config
}

_makeconf() {
  local file=$ROOTFS/etc/portage/make.conf
  local pkgdir="$ROOTFS/var/cache/binpkgs"
  local pkg_config="$ROOTFS/bin/pkg-config"
  # clean space
  sed -i -r 's/[ ]+"/ "/g' $file
  # config COMMON_FLAGS's march
  sed -i -r 's/(-march)=([^ "]+)/\1='$MARCH'/g' $file
  # config cbuild
  if [[ -z $(grep 'CHOST' $file) ]]; then
    echo "CHOST=\"${CHOST}\"" >> $file
  fi
  sed -i -r 's/CHOST.*/CHOST="'$CHOST'"/g' $file
  # config pkgdir
  # sed -i -r 's,(PKGDIR=").*",\1'${pkgdir}'",g' $file

  # config pkg_config
  _pkgconfig # google fix the library
  if [[ -z $(grep 'PKG_CONFIG' $file) ]]; then
    echo "PKG_CONFIG=\"${pkg_config}\"" >> $file
  fi
  sed -i -r 's,(PKG_CONFIG=").*",\1'${pkg_config}'",g' $file

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

    # ln make.profile, need $ROOTFS/var/db/repos/gentoo
    rm -rf $ROOTFS/etc/portage/make.profile
    ln -sf $PROFILE_MARCH $ROOTFS/etc/portage/make.profile
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
