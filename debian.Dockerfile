FROM debian:bookworm-slim AS build
WORKDIR /build

RUN apt update && apt install -y --no-install-recommends \
    git g++ make pkg-config libtool ca-certificates \
    libssl-dev zlib1g-dev liblmdb-dev libflatbuffers-dev \
    libsecp256k1-dev libzstd-dev

COPY . .
RUN git submodule update --init
RUN make setup-golpe
RUN make clean
RUN make -j4

FROM rust:1.82-slim-bookworm AS rust-build
WORKDIR /build

RUN apt update && apt install -y --no-install-recommends \
    build-essential gcc git && \
    git clone https://github.com/davidcaseria/noteguard.git && \
    cd noteguard && \
    git checkout allowed-kinds && \
    cargo build --release

FROM debian:bookworm-slim AS runner
WORKDIR /app

RUN apt update && apt install -y --no-install-recommends \
    liblmdb0 libflatbuffers-dev libsecp256k1-dev libb2-1 libzstd1 libssl3 \
    && rm -rf /var/lib/apt/lists/*

COPY --from=build /build/strfry strfry
COPY --from=build /build/strfry.conf strfry.conf
COPY --from=build /build/noteguard.toml noteguard.toml
COPY --from=rust-build /build/noteguard/target/release/noteguard noteguard
ENTRYPOINT ["/app/strfry"]
CMD ["relay"]