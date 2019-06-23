FROM alpine
MAINTAINER Etienne Dauvergne <contact@ekyna.com>

# https://github.com/mickaelperrin/docker-rsync-server/blob/master/Dockerfile
# https://github.com/Thrilleratplay/docker-ssh-rsync/blob/master/Dockerfile

# rc-update add rsyncd boot && \


# -e 's/^#UsePAM no/UsePAM no/g' \

RUN apk --update add \
  bash \
  tzdata \
  rsync \
  openssh && \
  rm -rf /var/cache/apk/* && \
  sed -i \
    -e 's/^UsePAM yes/#UsePAM yes/g' \
    -e 's/^#PermitRootLogin prohibit-password/PermitRootLogin yes/g' \
    -e 's/^PasswordAuthentication yes/PasswordAuthentication no/g' \
    -e 's/^#UseDNS yes/UseDNS no/g' \
  /etc/ssh/sshd_config && \
  /usr/bin/ssh-keygen -A

RUN echo "root:root" | chpasswd

# Open SSH port
EXPOSE 22

# Create entrypoint script
COPY docker-entrypoint.sh /
RUN chmod +x /docker-entrypoint.sh \
 && mkdir -p /docker-entrypoint.d

# Setup RSYNC
EXPOSE 873
COPY rsyncd.conf.tpl /etc/rsyncd.conf.tpl

# Default environment variables
ENV TZ="Europe/Paris" \
    LANG="C.UTF-8"

COPY authorized_keys /root/.ssh/

ENTRYPOINT [ "/docker-entrypoint.sh" ]

# RUN rsync in no daemon and expose errors to stdout
CMD [ "/usr/bin/rsync", "--no-detach", "--daemon", "--log-file=/dev/stdout" ]
