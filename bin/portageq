#!/bin/bash

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
FLEA_DIR=$(cd $SCRIPT_DIR/../ && pwd)

SCRIPT_NAME=$(echo $0|rev|cut -d "/" -f 1|rev|cut -d "." -f 1) sudo -E --shell $FLEA_DIR/lib/deliver.sh $@
