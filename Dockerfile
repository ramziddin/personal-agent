FROM nousresearch/hermes-agent:v2026.8.31

COPY --chmod=0755 scripts/bootstrap.sh /usr/local/bin/hermes-bootstrap
COPY --chown=hermes:hermes hermes/ /opt/hermes-bootstrap/

# Keep the upstream ENTRYPOINT so s6 remains PID 1 and drops privileges.
CMD ["/usr/local/bin/hermes-bootstrap"]
