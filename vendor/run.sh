#!/usr/bin/env bash

set -euo pipefail

### Detect project directory
SOURCE=${BASH_SOURCE[0]}
while [ -L "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  DIR=$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )
  SOURCE=$(readlink "$SOURCE")
  [[ $SOURCE != /* ]] && SOURCE=$DIR/$SOURCE # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
PROJECT_DIR=$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )


### Export path which python looks for modules
DIST_PACKAGES=${PROJECT_DIR}/dist-packages
export PYTHONPATH=$DIST_PACKAGES

# Run solaris exporter with extra args
/usr/bin/env python2.7 -m solaris_exporter.main $@
