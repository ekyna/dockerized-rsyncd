FROM alpine
MAINTAINER Etienne Dauvergne <contact@ekyna.com>

COPY rsyncd.conf.tpl /etc/rsyncd.conf.tpl
COPY supervisord.conf /etc/supervisor.conf
COPY entrypoint.sh /

RUN apk --update add \
     bash \
     tzdata \
     rsync \
     openssh \
     supervisor \
  && rm -rf /var/cache/apk/* \
  && mkdir /var/run/sshd \
  && mkdir -p /var/log/supervisor \
  && sed -i \
     -e 's/^UsePAM yes/#UsePAM yes/g' \
     -e 's/^#PermitRootLogin prohibit-password/PermitRootLogin prohibit-password/g' \
     -e 's/^PasswordAuthentication yes/PasswordAuthentication no/g' \
     -e 's/^#UseDNS yes/UseDNS no/g' \
     /etc/ssh/sshd_config \
  && /usr/bin/ssh-keygen -A \
  && echo "root:root" | chpasswd \
  && chmod +x /entrypoint.sh \
  && mkdir -p /entrypoint.d

EXPOSE 22
EXPOSE 873

# Default environment variables
ENV TZ="Europe/Paris" \
    LANG="C.UTF-8"

ENTRYPOINT [ "/entrypoint.sh" ]
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor.conf"]
