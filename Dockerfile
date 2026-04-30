# Build stage
FROM alpine:latest AS builder
ARG TARGETARCH
ENV ARCH=$TARGETARCH

# Install build dependencies
RUN set -ex &&\
  apk add --no-cache wget xz

# Download and extract s6-overlay
RUN set -ex &&\
  case "$ARCH" in \
    amd64) S6_ARCH=x86_64 ;; \
    arm64) S6_ARCH=aarch64 ;; \
    armv7) S6_ARCH=armhf ;; \
    *) S6_ARCH=x86_64 ;; \
  esac &&\
  wget -qO- https://github.com/just-containers/s6-overlay/releases/latest/download/s6-overlay-noarch.tar.xz | tar -C / -Jx &&\
  wget -qO- https://github.com/just-containers/s6-overlay/releases/latest/download/s6-overlay-$S6_ARCH.tar.xz | tar -C / -Jx

# Runtime stage
FROM alpine:latest
ARG TARGETARCH
ENV ARCH=$TARGETARCH

# Set working directory
WORKDIR /sing-box

# Copy s6-overlay files from build stage
COPY --from=builder / /

# Copy initialization script
COPY docker_init.sh /sing-box/init.sh

# Install runtime dependencies and generate certificates
RUN set -ex &&\
  apk add --no-cache wget nginx bash openssl &&\
  mkdir -p /sing-box/cert /sing-box/conf /sing-box/subscribe /sing-box/logs &&\
  chmod +x /sing-box/init.sh &&\
  rm -rf /var/cache/apk/*

CMD [ "./init.sh" ]
