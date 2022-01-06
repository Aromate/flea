#!/bin/bash

# Crossdev function

install_corssdev() {
  which crossdev 1>/dev/null 2>&1 || sudo emerge crossdev ||
    (echo "Can not install crossdev..." && exit 1)
}

create_crossdev_overlay() {
  mkdir -p /var/db/repos/crossdev/{profiles,metadata}
  echo 'crossdev' >/var/db/repos/crossdev/profiles/repo_name
  echo 'masters = gentoo' >/var/db/repos/crossdev/metadata/layout.conf
  echo 'thin-manifests = true' >>/var/db/repos/crossdev/metadata/layout.conf
  cat >/etc/portage/repos.conf/crossdev.conf <<EOF
  [crossdev]
  location = /var/db/repos/crossdev
  priority = 10
  masters = gentoo
  auto-sync = no
EOF
}

init_crossdev() {
  install_corssdev
  if [[ ! -f /etc/portage/repos.conf/crossdev.conf ]]; then
    create_crossdev_overlay
  fi
}

create_sdk() {
  if [[ $(ls /usr | grep $CHOST) == "" ]]; then
    crossdev --stable -t $CHOST ||
      (echo "Can not install crossdev sdk..." && exit 1)
  fi
}
