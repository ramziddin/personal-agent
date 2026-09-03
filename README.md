# Personal Agent

A small, public deployment project for running a private, always-on [Hermes Agent](https://hermes-agent.nousresearch.com/) on Railway through Telegram.

The deployment configuration and persona are public. Credentials, conversations, memories, user profile, learned skills, cron state, logs, and workspace files remain in Railway variables or the private persistent volume.

## Architecture

- `nousresearch/hermes-agent:v2026.8.31` provides the maintained runtime, non-root user, and s6 supervision.
- This repository layers in a public Hermes configuration and `SOUL.md`.
- A Railway volume mounted at `/opt/data` persists all private mutable state.
- Telegram uses long polling and accepts one explicitly allowlisted user.
- GitHub `main` is the Railway deployment source.

The bootstrap refreshes only `/opt/data/config.yaml` and `/opt/data/SOUL.md` on each start. It leaves memories, sessions, skills, cron jobs, and `/opt/data/workspace` untouched.

## Required credentials

Create a Railway service variable for each required value:

| Variable | Purpose |
| --- | --- |
| `GLM_API_KEY` | Z.AI model access |
| `TELEGRAM_BOT_TOKEN` | BotFather token |
| `TELEGRAM_ALLOWED_USERS` | Numeric Telegram user ID allowed to use the bot |
| `TELEGRAM_HOME_CHANNEL` | Delivery chat; for a personal DM, use the same numeric user ID |

Do not put real values in `.env.example`, GitHub Actions variables, issues, logs, or commits.

The default model is intentionally `glm-5.3-flash`. It was not listed in the public Z.AI catalog when this project was created. If Z.AI rejects it, inspect the exact provider response and deliberately choose another model; the deployment does not silently fall back.

## Deploy to Railway

Prerequisites:

- A public GitHub repository created from this project.
- Railway CLI 5.23.3 or newer, authenticated with `railway login`.
- A Z.AI API key, Telegram bot token, and your numeric Telegram user ID.

Create and link the project in the desired Railway workspace, create an empty service, and attach a volume at `/opt/data` before connecting the GitHub source. Enter secrets with Railway's dashboard or `railway variable set KEY --stdin`; avoid command-line values that can enter shell history.

This repository uses `.railway/railway.ts` as the desired project configuration. Always review the plan before applying it:

```sh
railway config plan
railway config apply
```

The desired deployment has one Amsterdam replica, the `hermes-data` volume, GitHub `main` as its source, and no public domain. Railway's default `ON_FAILURE` policy restarts the service up to ten times.

After deployment, wait for Railway to report `SUCCESS`, check bounded logs, and message the bot. A healthy gateway should connect in Telegram polling mode.

## Verify persistence

Ask the bot to create a harmless file in `/opt/data/workspace` and remember a test fact. Restart the Railway service, then confirm both the file and memory remain. Finally, create a short test cron job and confirm its result arrives in the configured home channel.

Enable daily backups from the service's **Backups** tab after the smoke test, and create an initial manual backup. Railway volume backups can only be restored within the same project and environment; wiping a volume also deletes its backups.

## Local checks

```sh
sh tests/bootstrap_test.sh
sh tests/repository_test.sh
shellcheck scripts/bootstrap.sh tests/*.sh
docker build --tag personal-agent:test .
docker run --rm personal-agent:test version
```

The Docker checks can run in CI when no local Docker daemon is available.

## Updating Hermes

The upstream image is pinned instead of using `latest`. Dependabot proposes Docker image updates weekly. Review the Hermes release notes, let CI build the candidate, and verify Telegram plus persistence before merging.

## License

MIT
