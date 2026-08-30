ARG BUILD_FROM=ghcr.io/home-assistant/amd64-base:3.22
FROM ${BUILD_FROM} AS builder

RUN apk add --no-cache build-base cmake
COPY src /src
RUN cmake -S /src -B /build -DCMAKE_BUILD_TYPE=Release \
    && cmake --build /build --parallel \
    && strip /build/inverter_poller

FROM ${BUILD_FROM}

ARG BUILD_ARCH
ARG BUILD_VERSION
LABEL io.hass.type="addon" io.hass.version="${BUILD_VERSION}" io.hass.arch="${BUILD_ARCH}"

RUN apk add --no-cache eudev jq mosquitto-clients util-linux
COPY --from=builder /build/inverter_poller /usr/local/bin/inverter_poller
COPY run.sh /run.sh
COPY mqtt-init.sh /usr/local/bin/mqtt-init
COPY mqtt-push.sh /usr/local/bin/mqtt-push
COPY mqtt-subscriber.sh /usr/local/bin/mqtt-subscriber
COPY mqtt-common.sh /usr/local/bin/mqtt-common
RUN sed -i 's/\r$//' /run.sh /usr/local/bin/mqtt-* \
    && chmod 0755 /run.sh /usr/local/bin/mqtt-*

CMD ["/run.sh"]

