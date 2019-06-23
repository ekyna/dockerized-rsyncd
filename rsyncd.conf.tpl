# /etc/rsyncd.conf

# Minimal configuration file for rsync daemon
# See rsync(1) and rsyncd.conf(5) man pages for help

# This line is required by the /etc/init.d/rsyncd script
pid file = /var/run/rsyncd.pid

uid = ${OWNER_ID}
gid = ${GROUP_ID}
use chroot = ${CHROOT}
reverse lookup = no

[${VOLUME_NAME}]
    hosts deny = *
    hosts allow = ${HOSTS_ALLOW}
    read only = ${READ_ONLY}
    path = ${VOLUME_PATH}
    auth users = , ${USERNAME}:rw
    secrets file = /etc/rsyncd.secrets
    timeout = 600
    transfer logging = true