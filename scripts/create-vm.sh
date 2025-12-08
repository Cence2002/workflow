#!/usr/bin/env bash
set -euo pipefail

if [ $# -lt 1 ]; then
  echo "[create-vm] Usage: $0 <vm-name>" >&2
  exit 1
fi

NAME="$1"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/config.sh"

# Ensure SSH directory exists
mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh" || true

SSH_KEY_PRIVATE="${SSH_KEY_PATH%.pub}"
if [ ! -f "$SSH_KEY_PRIVATE" ] || [ ! -f "$SSH_KEY_PATH" ]; then
  echo "[create-vm] SSH key not found, generating new key pair"
  ssh-keygen -t ed25519 -f "$SSH_KEY_PRIVATE" -N "" -C "$USER@$(hostname)"
  chmod 600 "$SSH_KEY_PRIVATE" || true
  chmod 644 "$SSH_KEY_PATH" || true
fi

MACHINE_TYPE="e2-micro"
DISK_SIZE="10GB"

SSH_METADATA="${SSH_USER}:$(cat "$SSH_KEY_PATH")"

echo "[create-vm] Creating '$NAME' (project: $GCP_PROJECT, zone: $GCP_ZONE, machine type: $MACHINE_TYPE, disk size: $DISK_SIZE)"
gcloud compute instances create "$NAME" \
  --project="$GCP_PROJECT" \
  --zone="$GCP_ZONE" \
  --machine-type="$MACHINE_TYPE" \
  --boot-disk-size="$DISK_SIZE" \
  --metadata=ssh-keys="$SSH_METADATA"

echo "[create-vm] Fetching external IP"
IP=$(gcloud compute instances describe "$NAME" \
  --project="$GCP_PROJECT" \
  --zone="$GCP_ZONE" \
  --format='get(networkInterfaces[0].accessConfigs[0].natIP)')

if [ -z "$IP" ]; then
  echo "[create-vm] External IP not found" >&2
  exit 1
fi

mkdir -p "$HOME/.ssh/vms"
CONFIG_FILE="$HOME/.ssh/vms/$NAME"

# Compute a portable path for ssh config (use ~ instead of hardcoded $HOME path)
KEY_FOR_CONFIG="$SSH_KEY_PRIVATE"
if [[ "$KEY_FOR_CONFIG" == "$HOME/"* ]]; then
  # Replace leading $HOME/... with ~/...
  KEY_FOR_CONFIG="~/${KEY_FOR_CONFIG#$HOME/}"
fi

cat > "$CONFIG_FILE" <<EOF
Host $NAME
    HostName $IP
    User $USER
    IdentityFile $KEY_FOR_CONFIG
    ForwardAgent yes
EOF

echo "[create-vm] Waiting for host to start"
ssh-keygen -R "$IP" >/dev/null 2>&1 || true
ssh-keygen -R "$NAME" >/dev/null 2>&1 || true

MAX_ATTEMPTS=60
ATTEMPT=0
while [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do
  if ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 "$NAME" "echo 'SSH connection successful'" >/dev/null 2>&1; then
    echo "[create-vm] Host is ready"
    break
  fi
  ATTEMPT=$((ATTEMPT + 1))
  if [ $ATTEMPT -lt $MAX_ATTEMPTS ]; then
    echo "[create-vm] Waiting for SSH (attempt $ATTEMPT/$MAX_ATTEMPTS)..."
    sleep 5
  else
    echo "[create-vm] Failed to connect to host after $MAX_ATTEMPTS attempts" >&2
    exit 1
  fi
done

echo "[create-vm] Installing git, cloning workflow and setting up"
ssh -t -o StrictHostKeyChecking=no "$NAME" \
  "sudo apt-get update -qq && \
   sudo apt-get install -y -qq git && \
   mkdir -p ~/projects && \
   cd ~/projects && \
   git clone $WORKFLOW_URL && \
   cd workflow && \
   ./scripts/setup-host.sh"

echo "[create-vm] Done"
