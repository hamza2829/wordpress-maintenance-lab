#!/usr/bin/env bash
# Upload a verified immutable release and atomically switch the current symlink.
set -Eeuo pipefail
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
: "${SSH_TARGET:?Set SSH_TARGET, for example deploy@127.0.0.1}"
: "${SSH_KEY:?Set SSH_KEY to a private key file}"
: "${SSH_KNOWN_HOSTS:?Set SSH_KNOWN_HOSTS to a trusted host-key file}"
SSH_PORT=${SSH_PORT:-2222}
DEPLOY_ROOT=${DEPLOY_ROOT:-/home/deploy/lab}
[[ "$SSH_TARGET" =~ ^[a-z_][a-z0-9_-]*@[a-zA-Z0-9.-]+$ && "$SSH_PORT" =~ ^[0-9]+$ ]] || { printf 'ERROR: invalid SSH destination.\n' >&2; exit 2; }
[[ "$DEPLOY_ROOT" =~ ^/[a-zA-Z0-9_/-]+$ && "$DEPLOY_ROOT" != '/' && "$DEPLOY_ROOT" != *'..'* ]] || { printf 'ERROR: unsafe deployment root.\n' >&2; exit 2; }
[[ -f "$SSH_KEY" && -f "$SSH_KNOWN_HOSTS" ]] || { printf 'ERROR: key or known-hosts file missing.\n' >&2; exit 2; }
options=(-p "$SSH_PORT" -i "$SSH_KEY" -o BatchMode=yes -o IdentitiesOnly=yes -o StrictHostKeyChecking=yes -o "UserKnownHostsFile=$SSH_KNOWN_HOSTS" -o ConnectTimeout=10)
release="$(git -C "$ROOT" rev-parse --short=12 HEAD)-$(date -u +%Y%m%dT%H%M%S)-$$"
remote="$DEPLOY_ROOT/releases/$release"
mkdir -p "$ROOT/.runtime" "$ROOT/artifacts"
printf 'Preparing release %s on %s.\n' "$release" "$SSH_TARGET"
ssh "${options[@]}" "$SSH_TARGET" "mkdir -p '$remote/themes' '$remote/plugins'"
printf -v transport '%q ' ssh "${options[@]}"
rsync -rlt --delete --safe-links -e "$transport" "$ROOT/site/themes/nordlicht-child/" "$SSH_TARGET:$remote/themes/nordlicht-child/"
rsync -rlt --delete --safe-links -e "$transport" "$ROOT/site/plugins/nordlicht-lab/" "$SSH_TARGET:$remote/plugins/nordlicht-lab/"
(cd "$ROOT/site" && find themes/nordlicht-child plugins/nordlicht-lab -type f -print0 | sort -z | xargs -0 sha256sum) > "$ROOT/.runtime/deploy-expected.sha256"
ssh "${options[@]}" "$SSH_TARGET" "cd '$remote' && find themes/nordlicht-child plugins/nordlicht-lab -type f -print0 | sort -z | xargs -0 sha256sum" > "$ROOT/.runtime/deploy-actual.sha256"
cmp "$ROOT/.runtime/deploy-expected.sha256" "$ROOT/.runtime/deploy-actual.sha256"
ssh "${options[@]}" "$SSH_TARGET" "ln -s 'releases/$release' '$DEPLOY_ROOT/.current-$release' && mv -Tf '$DEPLOY_ROOT/.current-$release' '$DEPLOY_ROOT/current'"
cp "$ROOT/.runtime/deploy-actual.sha256" "$ROOT/artifacts/deployed-files.sha256"
printf '%s\n' "$release" > "$ROOT/artifacts/deployed-release.txt"
printf 'Deployment passed: every file hash matched before the current link changed.\n'
