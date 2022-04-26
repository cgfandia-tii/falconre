FROM python:3.9-bullseye AS builder

RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y \
    build-essential \
    clang \
    curl \
    libz3-dev \
    pkg-config \
    wget && \
    apt-get clean

ENV RUSTUP_HOME=/usr/local/rustup \
    CARGO_HOME=/usr/local/cargo \
    PATH=/usr/local/cargo/bin:$PATH

RUN set -eux; \
    \
    url="https://static.rust-lang.org/rustup/dist/x86_64-unknown-linux-gnu/rustup-init"; \
    wget "$url"; \
    chmod +x rustup-init; \
    ./rustup-init -y --no-modify-path --default-toolchain nightly; \
    rm rustup-init; \
    chmod -R a+w $RUSTUP_HOME $CARGO_HOME; \
    rustup --version; \
    cargo --version; \
    rustc --version;

RUN wget https://github.com/aquynh/capstone/archive/4.0.2.tar.gz && \
    tar xf 4.0.2.tar.gz && \ 
    cd capstone-4.0.2 && \
    make -j 4 && make install

RUN pip3 install --no-cache-dir setuptools setuptools-rust

WORKDIR /falconre
COPY ./src /falconre/src
COPY ./Cargo.toml /falconre/Cargo.toml
COPY ./Cargo.lock /falconre/Cargo.lock
COPY ./falconre/ /falconre/falconre
COPY ./setup.py /falconre/setup.py

RUN python3 setup.py bdist_wheel

FROM python:3.9-bullseye

RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y \
    libz3-4 && \
    apt-get clean

COPY --from=builder /usr/lib/libcapstone.so.4 /usr/lib/
COPY --from=builder /falconre/dist/falconre-0.1.0-cp39-cp39-linux_x86_64.whl /tmp/falconre-0.1.0-cp39-cp39-linux_x86_64.whl
RUN pip3 install /tmp/falconre-0.1.0-cp39-cp39-linux_x86_64.whl && \
    rm -rf /tmp/falconre-0.1.0-cp39-cp39-linux_x86_64.whl

COPY requirements.txt .

RUN pip3 install --no-cache-dir -r requirements.txt