FROM steamcmd/steamcmd:latest

LABEL maintainer="skint007"

ENV STEAMAPPID=443030
ENV STEAMAPPDIR=/home/steam/conan-dedicated
ENV CONAN_ARGS="-log -nosteam"
ENV PUID=1000
ENV PGID=1000
ENV SERVER_EXE=ConanSandboxServer-Win64-Test.exe
ENV WINEPREFIX=/home/steam/.wine
ENV WINEARCH=win64

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ARG DEBIAN_FRONTEND=noninteractive

# Install Wine and other dependencies
RUN set -x \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        wine \
        wine32:i386 \
        wine64 \
        winbind \
        xvfb \
        xauth \
        cabextract \
        winetricks \
    # Create steam user and group (use -f to avoid failure if GID already exists)
    && groupadd -f -g 1000 steam \
    && useradd -m -o -u 1000 -g steam steam \
    # Create the game directory
    && mkdir -p "${STEAMAPPDIR}" \
    && chown steam:steam "${STEAMAPPDIR}" \
    # Clean up
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
