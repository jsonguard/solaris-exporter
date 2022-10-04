#!/usr/bin/bash

set -euo pipefail

export LANG=en_US.UTF-8

### Detect project directory
SOURCE=${BASH_SOURCE[0]}
while [ -L "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  DIR=$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )
  SOURCE=$(readlink "$SOURCE")
  [[ $SOURCE != /* ]] && SOURCE=$DIR/$SOURCE # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
PROJECT_DIR=$( cd -P "$( dirname "$SOURCE" )/.." >/dev/null 2>&1 && pwd )


### Export path which python looks for modules
DIST_PACKAGES=${PROJECT_DIR}/dist-packages
export PYTHONPATH=$DIST_PACKAGES

PID_FILE="${PWD}/solaris_exporter.pid"


usage() {
	echo "Usage: "
	echo "$0 start [application]"
	echo "$0 stop [application]"
	echo "$0 restart [application]"

start() {
  if test -f "$PID_FILE"; then
    PID="$(cat ${PID_FILE})"
    if ps -p $PID > /dev/null ; then
      echo "${PID_FILE} exist, probably exporter already running? "
      exit 1
    else
      echo "WARNING: ${PID_FILE} exist, but process with ID: ${PID} is not running"
      echo "WARNING: ${PID_FILE} is removed"
      /bin/rm -f ${PID_FILE}
    fi
  fi

  # Run solaris exporter with extra args
  /usr/bin/python2.7 -m solaris_exporter.main $@ &
  
  # Detect PID of exporter
  PID=$!
  echo "${PID}" > ${PID_FILE}
}

stop() {
  if test -f "$PID_FILE"; then
    PID="$(cat ${PID_FILE})"
    kill -TERM $PID
    /bin/rm -f ${PID_FILE}
  else
    echo "Solaris exporter is not running"
    exit 1
  fi
}

case "$1" in
	start)
		shift
		start $* || exit 1
		;;
	stop)
		shift
		stop $* || exit 1
		;;
	restart)
		shift
		stop $* || exit 1
		start $* || exit 1
		;;
	*)
		usage && exit 0
		;;
esac
