#!/usr/bin/env bash
set -euo pipefail

# EmlidReach_scp_transfer.sh
# POSIX-compatible script to transfer files from an Emlid Reach receiver to a local directory.
# Behavior mirrors the Windows WinSCP batch in this repo:
#  - default host: 192.168.42.1
#  - default user: reach
#  - default remote path: /data/logs/
#  - default local save dir: $HOME/GNSS_PROJECT/<SSID>/<YYYY-MM-DD>
#
# Usage examples:
#  ./EmlidReach_scp_transfer.sh                 # use defaults, interactive scp (prompts for password)
#  ./EmlidReach_scp_transfer.sh -p emlidreach    # pass password (uses sshpass if installed)
#  ./EmlidReach_scp_transfer.sh -s MY_SSID       # override detected SSID
#  ./EmlidReach_scp_transfer.sh -h 10.0.0.2 -u user -r /path/on/reach -d /tmp/mydir
#
# Notes:
#  - For non-interactive password use this script with sshpass installed (not always present by default).
#  - Recommended: set up SSH key auth on the receiver for passwordless, secure transfers.

HOST_DEFAULT="192.168.42.1"
USER_DEFAULT="reach"
REMOTE_PATH_DEFAULT="/data/logs/"

HOST="$HOST_DEFAULT"
USER="$USER_DEFAULT"
REMOTE_PATH="$REMOTE_PATH_DEFAULT"
PASSWORD=""
SSID_OVERRIDE=""
LOCAL_BASE="$HOME/GNSS_PROJECT"

print_usage() {
  cat <<EOF
Usage: $0 [options]

Options:
  -h host        Remote host (default: ${HOST_DEFAULT})
  -u user        Remote user (default: ${USER_DEFAULT})
  -p password    Remote password (optional; if provided and sshpass present it will be used)
  -r remote-path Remote path on device (default: ${REMOTE_PATH_DEFAULT})
  -d local-dir   Local base directory (default: ${LOCAL_BASE})
  -s ssid        Override detected SSID to use in output path
  -n             No-password mode (assume key-based auth; do not prompt)
  -?             Show this help

Examples:
  $0
  $0 -p emlidreach
  $0 -s "MyHotspot" -d /tmp/gnss
EOF
}

detect_ssid() {
  # Try a few methods (Linux/macOS)
  local ssid=""

  # nmcli (NetworkManager)
  if command -v nmcli >/dev/null 2>&1; then
    ssid=$(nmcli -t -f ACTIVE,SSID dev wifi 2>/dev/null | awk -F: '$1=="yes"{print $2; exit}') || true
  fi

  # iwgetid (wireless-tools)
  if [ -z "$ssid" ] && command -v iwgetid >/dev/null 2>&1; then
    ssid=$(iwgetid -r 2>/dev/null || true)
  fi

  # macOS: networksetup
  if [ -z "$ssid" ] && command -v networksetup >/dev/null 2>&1; then
    # Try common device names: en0 en1
    for dev in en0 en1; do
      out=$(networksetup -getairportnetwork "$dev" 2>/dev/null || true)
      case "$out" in
        "Current Wi-Fi Network:"*) ssid=${out#Current Wi-Fi Network: } ; break ;;
      esac
    done
  fi

  # macOS: airport (private framework)
  if [ -z "$ssid" ] && [ -x "/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport" ]; then
    ssid=$(/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport -I 2>/dev/null | awk -F": " '/ SSID/{print $2; exit}') || true
  fi

  # Fallback: empty
  echo "$ssid"
}

main() {
  local no_password_mode=0

  while getopts ":h:u:p:r:d:s:n:?" opt; do
    case $opt in
      h) HOST="$OPTARG" ;;
      u) USER="$OPTARG" ;;
      p) PASSWORD="$OPTARG" ;;
      r) REMOTE_PATH="$OPTARG" ;;
      d) LOCAL_BASE="$OPTARG" ;;
      s) SSID_OVERRIDE="$OPTARG" ;;
      n) no_password_mode=1 ;;
      ?) print_usage; exit 0 ;;
    esac
  done

  DATE=$(date +%F)

  if [ -n "$SSID_OVERRIDE" ]; then
    SSID="$SSID_OVERRIDE"
  else
    SSID=$(detect_ssid)
    if [ -z "$SSID" ]; then
      echo "Warning: could not detect SSID. Using 'UNKNOWN' as fallback. You may pass -s to override." >&2
      SSID="UNKNOWN"
    fi
  fi

  # sanitize SSID for directory name
  SSID_SAFE=$(echo "$SSID" | tr '/\\' '_' | tr -s ' ' '_' )

  OUTDIR="$LOCAL_BASE/$SSID_SAFE/$DATE"
  mkdir -p "$OUTDIR"

  echo "Transferring files from ${USER}@${HOST}:${REMOTE_PATH} to ${OUTDIR}"

  # If password provided and sshpass exists, prefer sshpass+scp for automated non-interactive transfer
  if [ -n "$PASSWORD" ] && command -v sshpass >/dev/null 2>&1; then
    echo "Using sshpass (non-interactive)."
    # Use scp to copy files; wildcard expansion is performed on remote side by the shell on many devices.
    sshpass -p "$PASSWORD" scp -o StrictHostKeyChecking=no -r "$USER@$HOST:$REMOTE_PATH"* "$OUTDIR" || {
      echo "scp via sshpass failed; trying sftp fallback..." >&2
    }
  fi

  # If OUTDIR is empty (no files copied yet) or sshpass was not used, try scp (interactive) or sftp batch
  # First try scp (will prompt if no key and no sshpass)
  # Use -r to get directories if present
  echo "Attempting scp (may prompt for password if required)..."
  if scp -o BatchMode="yes" -o ConnectTimeout=10 -r "$USER@$HOST:$REMOTE_PATH"* "$OUTDIR" 2>/dev/null; then
    echo "Files copied with key-based auth or no auth prompt." 
  else
    # Try interactive scp (prompts for password)
    if scp -r "$USER@$HOST:$REMOTE_PATH"* "$OUTDIR"; then
      echo "Files copied via interactive scp."
    else
      # As last resort try sftp batch (will prompt if needed)
      echo "scp failed. Trying sftp batch mode..."
      if command -v sshpass >/dev/null 2>&1 && [ -n "$PASSWORD" ]; then
        sshpass -p "$PASSWORD" sftp -o StrictHostKeyChecking=no "$USER@$HOST" <<EOF
cd $REMOTE_PATH
lcd $OUTDIR
mget *
bye
EOF
      else
        sftp "$USER@$HOST" <<EOF
cd $REMOTE_PATH
lcd $OUTDIR
mget *
bye
EOF
      fi
    fi
  fi

  echo "===== Transfer finalized ====="
  echo "Files saved in: ${OUTDIR}"
}

main "$@"
