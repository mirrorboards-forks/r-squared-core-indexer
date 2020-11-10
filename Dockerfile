FROM phusion/baseimage:0.11 AS build
MAINTAINER The Revolution Populi Project

ENV LANG=en_US.UTF-8
RUN \
    apt-get update -y && \
    apt-get install -y \
      g++ \
      autoconf \
      cmake \
      git \
      libbz2-dev \
      libcurl4-openssl-dev \
      libssl-dev \
      libncurses-dev \
      libboost-thread-dev \
      libboost-iostreams-dev \
      libboost-date-time-dev \
      libboost-system-dev \
      libboost-filesystem-dev \
      libboost-program-options-dev \
      libboost-chrono-dev \
      libboost-test-dev \
      libboost-context-dev \
      libboost-regex-dev \
      libboost-coroutine-dev \
      libtool \
      doxygen \
      ca-certificates \
      fish \
    && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ADD . /revpop-core
WORKDIR /revpop-core

# Compile
RUN \
    ( git submodule sync --recursive || \
      find `pwd`  -type f -name .git | \
	while read f; do \
	  rel="$(echo "${f#$PWD/}" | sed 's=[^/]*/=../=g')"; \
	  sed -i "s=: .*/.git/=: $rel/=" "$f"; \
	done && \
      git submodule sync --recursive ) && \
    git submodule update --init --recursive && \
    cmake \
        -DCMAKE_BUILD_TYPE=Release \
	-DGRAPHENE_DISABLE_UNITY_BUILD=ON \
        . && \
    make witness_node cli_wallet get_dev_key && \
    install -s programs/witness_node/witness_node programs/genesis_util/get_dev_key programs/cli_wallet/cli_wallet /usr/local/bin && \
    #
    # Obtain version
    mkdir /etc/revpop && \
    git rev-parse --short HEAD > /etc/revpop/version && \
    cd / && \
    rm -rf /revpop-core

# Home directory $HOME
WORKDIR /
RUN useradd -s /bin/bash -m -d /var/lib/revpop revpop
ENV HOME /var/lib/revpop
RUN chown revpop:revpop -R /var/lib/revpop

# Volume
VOLUME ["/var/lib/revpop", "/etc/revpop"]

# rpc service:
EXPOSE 8090
# p2p service:
EXPOSE 1776

# default exec/config files
ADD docker/revpop/default_config.ini /etc/revpop/config.ini
ADD docker/revpop/default_logging.ini /etc/revpop/logging.ini
ADD docker/revpop/my-genesis.json /etc/revpop/genesis.json
ADD docker/revpop/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod a+x /usr/local/bin/entrypoint.sh

# Make Docker send SIGINT instead of SIGTERM to the daemon
STOPSIGNAL SIGINT

# default execute entry
CMD ["/usr/local/bin/entrypoint.sh"]

FROM phusion/baseimage:0.11 AS run
MAINTAINER The Revolution Populi Project

COPY --from=build /usr/local/bin /usr/local/bin

# Home directory $HOME
WORKDIR /
RUN useradd -s /bin/bash -m -d /var/lib/revpop revpop
ENV HOME /var/lib/revpop
RUN chown revpop:revpop -R /var/lib/revpop

# Volume
VOLUME ["/var/lib/revpop", "/etc/revpop"]

# rpc service:
EXPOSE 8090
# p2p service:
EXPOSE 1776

# default exec/config files
ADD docker/revpop/default_config.ini /etc/revpop/config.ini
ADD docker/revpop/default_logging.ini /etc/revpop/logging.ini
ADD docker/revpop/my-genesis.json /etc/revpop/genesis.json
ADD docker/revpop/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod a+x /usr/local/bin/entrypoint.sh

# Make Docker send SIGINT instead of SIGTERM to the daemon
STOPSIGNAL SIGINT

# default execute entry
CMD ["/usr/local/bin/entrypoint.sh"]
