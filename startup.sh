#!/bin/bash

# ---- User/Group Configuration ----
PUID=${PUID:-1000}
PGID=${PGID:-1000}

groupmod -o -g "$PGID" steam
usermod -o -u "$PUID" steam

echo "-------------------------------------"
echo " User uid: $(id -u steam)"
echo " User gid: $(id -g steam)"
echo "-------------------------------------"

chown steam:steam -R /home/steam

# ---- Game Update ----
echo "-------------------------------------"
echo " Updating Conan Exiles Dedicated Server..."
echo "-------------------------------------"

set -x
su steam -c "steamcmd \
    +@sSteamCmdForcePlatformType windows \
    +force_install_dir ${STEAMAPPDIR} \
    +login anonymous \
    +app_update ${STEAMAPPID} validate \
    +quit"
set +x

# ---- Mod Management ----
echo "-------------------------------------"
echo " Processing mods..."
echo "-------------------------------------"

STEAMSERVERID=440900
GAMEMODDIR="${STEAMAPPDIR}/ConanSandbox/Mods"
GAMEMODLIST="${GAMEMODDIR}/modlist.txt"

# Create modlist.txt in the volume root if it doesn't exist
if [ ! -f "${STEAMAPPDIR}/modlist.txt" ]; then
    echo "No modlist found, creating empty ${STEAMAPPDIR}/modlist.txt"
    su steam -c "touch ${STEAMAPPDIR}/modlist.txt"
fi

# Ensure mod directory exists and clear server modlist
su steam -c "mkdir -p ${GAMEMODDIR}"
echo "" > "${GAMEMODLIST}"

MODS=$(awk '{print $1}' "${STEAMAPPDIR}/modlist.txt" | grep -v '^$')

if [ -n "${MODS}" ]; then
    # Build steamcmd command with all mod downloads
    MODCMD="steamcmd +@sSteamCmdForcePlatformType windows +login anonymous"
    for MODID in ${MODS}; do
        echo "Adding mod ${MODID} to download list..."
        MODCMD="${MODCMD} +workshop_download_item ${STEAMSERVERID} ${MODID}"
    done
    MODCMD="${MODCMD} +quit"

    set -x
    su steam -c "${MODCMD}"
    set +x

    # Link mod .pak files into the game's mod directory
    echo "Linking mod files..."
    for MODID in ${MODS}; do
        MODDIR=""
        for SEARCHDIR in \
            "/home/steam/.local/share/Steam/steamapps/workshop/content/${STEAMSERVERID}/${MODID}" \
            "/home/steam/Steam/steamapps/workshop/content/${STEAMSERVERID}/${MODID}" \
            "/root/.local/share/Steam/steamapps/workshop/content/${STEAMSERVERID}/${MODID}"; do
            if [ -d "${SEARCHDIR}" ]; then
                MODDIR="${SEARCHDIR}"
                break
            fi
        done

        if [ -n "${MODDIR}" ]; then
            echo "Linking mod ${MODID}..."
            find "${MODDIR}" -iname '*.pak' >> "${GAMEMODLIST}"
        else
            echo "WARNING: Mod ${MODID} directory not found!"
        fi
    done
else
    echo "No mods configured."
fi

# ---- Start Xvfb ----
echo "-------------------------------------"
echo " Starting virtual display..."
echo "-------------------------------------"

DISPLAY_NUM=99
Xvfb :${DISPLAY_NUM} -screen 0 1024x768x16 &
export DISPLAY=:${DISPLAY_NUM}

# Give Xvfb a moment to start
sleep 2

# ---- Initialize Wine Prefix ----
echo "-------------------------------------"
echo " Initializing Wine prefix..."
echo "-------------------------------------"

# Only initialize if the prefix doesn't exist yet
if [ ! -d "${WINEPREFIX}" ]; then
    echo "Creating new Wine prefix at ${WINEPREFIX}..."
    su steam -c "DISPLAY=:${DISPLAY_NUM} WINEPREFIX=${WINEPREFIX} WINEARCH=${WINEARCH} wineboot --init" 2>&1
    su steam -c "DISPLAY=:${DISPLAY_NUM} WINEPREFIX=${WINEPREFIX} wineserver --wait" 2>&1 || true

    echo "Installing Visual C++ runtime..."
    su steam -c "DISPLAY=:${DISPLAY_NUM} WINEPREFIX=${WINEPREFIX} WINEARCH=${WINEARCH} winetricks -q vcrun2022" 2>&1
    su steam -c "DISPLAY=:${DISPLAY_NUM} WINEPREFIX=${WINEPREFIX} wineserver --wait" 2>&1 || true
else
    echo "Wine prefix already exists, skipping initialization."
fi

# ---- Launch Server ----
echo "-------------------------------------"
echo " Starting Conan Exiles Dedicated Server..."
echo "-------------------------------------"

SERVER_EXE=${SERVER_EXE:-"ConanSandboxServer-Win64-Test.exe"}

exec su steam -c "DISPLAY=:${DISPLAY_NUM} WINEPREFIX=${WINEPREFIX} WINEARCH=${WINEARCH} wine ${STEAMAPPDIR}/${SERVER_EXE} ${CONAN_ARGS}"
