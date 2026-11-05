#!/usr/bin/env bash
set -Eeuo pipefail
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=scripts/lib.sh
source "$SCRIPT_DIR/lib.sh"
mkdir -p "$ROOT/.runtime/ssh"
for key in host_key client_key wrong_key; do
  if [[ ! -f "$ROOT/.runtime/ssh/$key" ]]; then ssh-keygen -q -t ed25519 -N '' -f "$ROOT/.runtime/ssh/$key"; fi
done
printf '[127.0.0.1]:2222 %s\n' "$(cat "$ROOT/.runtime/ssh/host_key.pub")" > "$ROOT/.runtime/ssh/known_hosts"
dc --profile ssh up -d --build ssh
export SSH_TARGET=deploy@127.0.0.1
export SSH_KEY="$ROOT/.runtime/ssh/client_key"
export SSH_KNOWN_HOSTS="$ROOT/.runtime/ssh/known_hosts"
export SSH_PORT=2222
options=(-p "$SSH_PORT" -i "$SSH_KEY" -o BatchMode=yes -o IdentitiesOnly=yes -o StrictHostKeyChecking=yes -o "UserKnownHostsFile=$SSH_KNOWN_HOSTS")
ready=0
for attempt in {1..30}; do
  if ssh "${options[@]}" "$SSH_TARGET" 'printf key-login-ok' > "$ROOT/artifacts/ssh-login.log" 2> "$ROOT/artifacts/ssh-ready.log"; then ready=1; break; fi
  sleep 2
done
[[ "$ready" == 1 ]] || { message 'ERROR: SSH did not become ready.' >&2; exit 1; }
grep -q 'key-login-ok' "$ROOT/artifacts/ssh-login.log"
cd "$ROOT"
python3 ci/record_case.py ssh-key-login
set +e
ssh -p 2222 -i "$ROOT/.runtime/ssh/wrong_key" -o BatchMode=yes -o IdentitiesOnly=yes -o StrictHostKeyChecking=yes -o "UserKnownHostsFile=$SSH_KNOWN_HOSTS" "$SSH_TARGET" true > "$ROOT/artifacts/ssh-rejected.log" 2>&1
status=$?
set -e
[[ "$status" == 255 ]] && grep -q 'Permission denied' "$ROOT/artifacts/ssh-rejected.log"
python3 ci/record_case.py ssh-failed-login
bash "$SCRIPT_DIR/deploy.sh" | tee "$ROOT/artifacts/deploy.log"
[[ -s "$ROOT/artifacts/deployed-files.sha256" ]]
python3 ci/record_case.py ssh-rsync-content
before=$(ssh "${options[@]}" "$SSH_TARGET" 'readlink /home/deploy/lab/current')
set +e
SSH_KEY="$ROOT/.runtime/ssh/wrong_key" bash "$SCRIPT_DIR/deploy.sh" > "$ROOT/artifacts/deploy-rejected.log" 2>&1
status=$?
set -e
[[ "$status" != 0 ]] || { message 'ERROR: unauthorized deployment unexpectedly succeeded.' >&2; exit 1; }
after=$(ssh "${options[@]}" "$SSH_TARGET" 'readlink /home/deploy/lab/current')
[[ "$before" == "$after" ]]
python3 ci/record_case.py ssh-rejected-deploy-unchanged
message 'SSH key login, rejected login, rsync hashes and rejected deployment checks passed.'
