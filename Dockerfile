FROM ubuntu:latest

MAINTAINER Guillaume Poirier-Morency <guillaumepoiriermorency@gmail.com>

RUN apt-get update && apt-get install -y \
    libfcgi-dev                          \
    libglib2.0-dev                       \
    libsoup2.4-dev                       \
    gobject-introspection                \
    python3-pip                          \
    unzip                                \
    valac                                \
    && rm -rf /var/lib/apt/lists/*

# Meson
RUN pip3 install meson

# Ninja
ADD https://github.com/ninja-build/ninja/releases/download/v1.6.0/ninja-linux.zip /tmp
RUN unzip /tmp/ninja-linux.zip -d /usr/local/bin

WORKDIR /valum
ADD . .

RUN mkdir build && meson --prefix=/usr --buildtype=release -D with_introspection=true . build && ninja -C build && ninja -C build test && ninja -C build install
