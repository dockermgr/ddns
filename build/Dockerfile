FROM alpine:latest as ddnsBase
LABEL author="CasjaysDev" \
  email="<docker-admin@casjaysdev.com>" \
  version="1.0.0" \
  description="dynamic-dns server"

RUN apk update --no-cache && apk add --no-cache dhcp-server-vanilla radvd bind bash php8 tftp-hpa tor
RUN rm -Rf /var/cache/apk/* /etc/named* /etc/bind* /etc/dhcpd* /etc/radvd* /etc/tor* /bin/ash
RUN ln -sf /bin/bash /bin/ash

FROM ddnsBase
LABEL author="CasjaysDev" \
  email="<docker-admin@casjaysdev.com>" \
  version="1.0.0" \
  description="dynamic-dns server"

EXPOSE 53 53/udp 67 67/udp 69 69/udp 546 546/udp

COPY ./files /var/lib/ddns
COPY ./bin/entrypoint.sh /usr/bin/entrypoint.sh

VOLUME ["/data", "/config"]

ENV HOSTNAME="ddns"

HEALTHCHECK CMD /usr/bin/entrypoint.sh --health; exit $?

ENTRYPOINT ["/usr/bin/entrypoint.sh"]
