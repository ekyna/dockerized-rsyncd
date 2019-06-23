pid file = /var/run/rsyncd.pid
log file = /dev/stdout

uid = ${USER_ID}
gid = ${GROUP_ID}
use chroot = ${CHROOT}
reverse lookup = no

[mirror]
    hosts deny = *
    hosts allow = ${HOSTS_ALLOW}
    read only = ${READ_ONLY}
    path = /data/mirror
    timeout = 600
    transfer logging = true

[full]
    hosts deny = *
    hosts allow = ${HOSTS_ALLOW}
    read only = ${READ_ONLY}
    path = /data/full
    timeout = 600
    transfer logging = true
