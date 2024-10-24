# Built by Akito
# npub1wprtv89px7z2ut04vvquscpmyfuzvcxttwy2csvla5lvwyj807qqz5aqle

FROM alpine:3.18 AS build

ENV TZ=Etc/UTC

WORKDIR /build

COPY . .

RUN \
  apk --no-cache add \
  linux-headers \
  git \
  g++ \
  make \
  perl \
  pkgconfig \
  libtool \
  ca-certificates \
  libressl-dev \
  zlib-dev \
  lmdb-dev \
  flatbuffers-dev \
  libsecp256k1-dev \
  zstd-dev \
  && rm -rf /var/cache/apk/* \
  && git submodule update --init \
  && make setup-golpe \
  && make -j4

FROM rust:1.82.0-alpine3.18 AS rust-build

WORKDIR /build

RUN apk --no-cache add build-base gcc git libc6-compat musl-dev && \
  git clone https://github.com/davidcaseria/noteguard.git && \
  cd noteguard && \
  git checkout allowed-kinds && \
  cargo build --target x86_64-unknown-linux-musl --release

FROM alpine:3.18

WORKDIR /app

RUN \
  apk --no-cache add \
  lmdb \
  flatbuffers \
  libsecp256k1 \
  libb2 \
  zstd \
  libressl \
  && rm -rf /var/cache/apk/*

COPY --from=build /build/strfry strfry
COPY --from=build /build/strfry.conf strfry.conf
COPY --from=build /build/noteguard.toml noteguard.toml
COPY --from=rust-build /build/noteguard/target/x86_64-unknown-linux-musl/release/noteguard noteguard

EXPOSE 7777

ENTRYPOINT ["/app/strfry"]
CMD ["relay"]
