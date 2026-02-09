FROM steamcmd/steamcmd:latest

LABEL maintainer="skint007"

ENV STEAMAPPID=443030
ENV STEAMAPPDIR=/home/steam/conan-dedicated
ENV CONAN_ARGS="-log -nosteam"
ENV PUID=1000
ENV PGID=1000
ENV SERVER_EXE=ConanSandboxServer-Win64-Test.exe

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ARG DEBIAN_FRONTEND=noninteractive

# Install Wine via WineHQ repository and other dependencies
RUN set -x \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        software-properties-common \
        gpg-agent \
        wget \
    # Add WineHQ GPG key and repository (Ubuntu Noble)
    && mkdir -pm755 /etc/apt/keyrings \
    && wget -O /etc/apt/keyrings/winehq-archive.key \
        https://dl.winehq.org/wine-builds/winehq.key \
    && wget -NP /etc/apt/sources.list.d/ \
        https://dl.winehq.org/wine-builds/ubuntu/dists/noble/winehq-noble.sources \
    && apt-get update \
    # Install Wine (--install-recommends required for Wine's 32-bit libraries)
    && apt-get install -y --install-recommends \
        winehq-stable \
    && apt-get install -y --no-install-recommends \
        winbind \
        xvfb \
        xauth \
    # Create steam user and group
    && groupadd -g 1000 steam \
    && useradd -m -u 1000 -g steam steam \
    # Create the game directory
    && mkdir -p "${STEAMAPPDIR}" \
    && chown steam:steam "${STEAMAPPDIR}" \
    # Clean up
    && apt-get remove --purge -y \
        software-properties-common \
        gpg-agent \
        wget \
    && apt-get clean autoclean \
    && apt-get autoremove -y \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

WORKDIR ${STEAMAPPDIR}

VOLUME ${STEAMAPPDIR}

EXPOSE 7777/udp 7778/udp 27015/udp

COPY startup.sh /root/startup.sh
RUN chmod +x /root/startup.sh

ENTRYPOINT ["/root/startup.sh"]
CMD []
