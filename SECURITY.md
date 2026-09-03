# Security policy

## Secrets and private data

Never commit API keys, bot tokens, Telegram IDs, exported Hermes state, or Railway volume contents. Store deployment credentials in Railway service variables. If a secret reaches Git history, revoke it before rewriting history.

Hermes runs with broad tool access and command approvals disabled. This is intentional for a single-user, agent-exclusive container. The deployment still relies on these boundaries:

- Telegram accepts only the configured numeric user ID.
- The upstream image runs Hermes as a non-root user.
- The Hermes installation under `/opt/hermes` is immutable.
- Durable application state stays under `/opt/data`; non-root permissions keep the installed Hermes tree under `/opt/hermes` immutable.
- Hermes filters credentials from terminal and code-execution subprocesses and redacts secrets from output.

Do not expose the Hermes dashboard, API server, or a public Railway domain without adding authentication and reviewing the upstream security guidance.

## Reporting a vulnerability

Open a GitHub security advisory for repository-specific issues. Report Hermes runtime vulnerabilities to the upstream NousResearch project.
