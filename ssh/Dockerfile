FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y --no-install-recommends openssh-server rsync ca-certificates && rm -rf /var/lib/apt/lists/* \
    && useradd --create-home --shell /bin/bash deploy \
    && echo 'deploy:unused-container-password' | chpasswd \
    && mkdir -p /run/sshd /home/deploy/.ssh \
    && chown -R deploy:deploy /home/deploy
COPY sshd_config /etc/ssh/sshd_config.lab
COPY entrypoint.sh /entrypoint.sh
RUN chmod 0755 /entrypoint.sh
EXPOSE 22
ENTRYPOINT ["/entrypoint.sh"]
