#!/usr/bin/env bash
set -euo pipefail
cp /keys/host_key /etc/ssh/ssh_host_ed25519_key
cp /keys/host_key.pub /etc/ssh/ssh_host_ed25519_key.pub
cp /keys/client_key.pub /home/deploy/.ssh/authorized_keys
chmod 0600 /etc/ssh/ssh_host_ed25519_key /home/deploy/.ssh/authorized_keys
chmod 0700 /home/deploy/.ssh
chown -R deploy:deploy /home/deploy/.ssh
exec /usr/sbin/sshd -D -e -f /etc/ssh/sshd_config.lab
