#!/bin/bash
set -e

if [[ "$1" == 'ssh-allow' ]]
then
    sed -i \
        -e 's/^PermitRootLogin prohibit-password/PermitRootLogin yes/g' \
        /etc/ssh/sshd_config
    supervisorctl -c /etc/supervisor.conf restart ssh
    exit $?
elif [[ "$1" == 'ssh-deny' ]]
then
    sed -i \
        -e 's/^PermitRootLogin yes/PermitRootLogin prohibit-password/g' \
        /etc/ssh/sshd_config
    supervisorctl -c /etc/supervisor.conf restart ssh
    exit $?
elif [[ "$1" == '/usr/bin/supervisord' ]]
then
  if [[ -n ${TZ} ]] && [[ -f /usr/share/zoneinfo/${TZ} ]]
  then
    ln -sf /usr/share/zoneinfo/${TZ} /etc/localtime
    echo ${TZ} > /etc/timezone
  fi

  if [[ ! -e /data/mirror ]]
  then
    mkdir -p /data/mirror
  fi
  if [[ ! -e /data/full ]]
  then
    mkdir -p /data/full
  fi

  chown -R ${USER_ID}:${GROUP_ID} /data

  eval "echo \"$(cat /etc/rsyncd.conf.tpl)\"" > /etc/rsyncd.conf

  for f in /entrypoint.d/*
  do
    case "$f" in
      *.sh)  echo "$0: running $f"; . "$f" ;;
      *)     echo "$0: ignoring $f" ;;
    esac
  done
fi

exec "$@"
