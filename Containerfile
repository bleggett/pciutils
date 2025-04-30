FROM alpine:3.18

RUN apk add --no-cache \
    alpine-sdk \
    musl-dev \
    zlib-dev \
    zlib-static \
    linux-headers \
    wget \
    make \
    gcc \
    git

WORKDIR /build

RUN git clone https://github.com/pciutils/pciutils.git .

RUN make clean && \
    LDFLAGS="-static" \
    CC="gcc -static" \
    CFLAGS="-Os -ffunction-sections -fdata-sections" \
    make SHARED=no \
         DNS=no \
         ZLIB=yes \
         # UDEV=no \
         PREFIX=/usr \
         SBINDIR=/usr/bin \
         all

RUN file ./lspci | grep "statically linked"
RUN ./update-pciids.sh

FROM scratch
COPY --from=0 /build/lspci /lspci
COPY --from=0 /build/setpci /setpci
COPY --from=0 /build/update-pciids /update-pciids
COPY --from=0 /build/pci.ids /usr/share/hwdata/pci.ids
ENTRYPOINT ["/lspci", "-vvv"]
