FROM ubuntu:22.04

## Install build dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    cmake \
    git \
    pkg-config \
    ncurses-dev \
    libssl-dev \
    sudo \
    python3 \
    curl

## Install erlang from source
RUN git clone https://github.com/erlang/otp.git && \
    cd otp && \
    git checkout maint-27 && \
    ./configure && \
    make -j16 && \
    sudo make install

## Install rebar3 from source
RUN git clone https://github.com/erlang/rebar3.git && \
    cd rebar3 && \
    ./bootstrap && \
    sudo mv rebar3 /usr/local/bin/

## Install rust from source
# RUN git clone https://github.com/rust-lang/rust.git && \
#     cd rust && \
#     ./configure && \
#     make && \
#     sudo make install

## Install rust from rustup (faster, recommended)
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- \
    --default-toolchain 1.86.0 -y
ENV PATH="/root/.cargo/bin:${PATH}"

WORKDIR /app
ARG BUMP=HI2
RUN git clone https://github.com/permaweb/hyperbeam.git .

RUN rebar3 compile

CMD ["/bin/bash"]
