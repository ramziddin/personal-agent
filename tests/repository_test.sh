#!/bin/sh
set -eu

required_files='Dockerfile
.dockerignore
.env.example
.gitignore
.railway/railway.ts
hermes/config.yaml
hermes/SOUL.md
LICENSE
README.md
SECURITY.md'

printf '%s\n' "$required_files" | while IFS= read -r file; do
  test -f "$file" || {
    printf 'Missing required file: %s\n' "$file" >&2
    exit 1
  }
done

grep -q '^FROM nousresearch/hermes-agent:v2026.8.31$' Dockerfile
grep -q '^CMD \["/usr/local/bin/hermes-bootstrap"\]$' Dockerfile
if grep -q '^ENTRYPOINT' Dockerfile; then
  printf '%s\n' 'Dockerfile must retain the upstream entrypoint' >&2
  exit 1
fi

ruby -ryaml - <<'RUBY'
config = YAML.safe_load(File.read("hermes/config.yaml"), permitted_classes: [], aliases: false)
raise unless config["_config_version"] == 39
raise unless config["model"] == {"provider" => "zai", "default" => "glm-5.3-flash"}
raise unless config.dig("terminal", "backend") == "local"
raise unless config.dig("terminal", "cwd") == "/opt/data/workspace"
raise unless config.dig("platform_toolsets", "telegram") == ["hermes-telegram"]
raise unless config.dig("memory", "memory_enabled") == true
raise unless config.dig("memory", "user_profile_enabled") == true
raise unless config["session_reset"] == {"mode" => "idle", "idle_minutes" => 1440}
raise unless config.dig("approvals", "mode") == "off"
raise unless config.dig("approvals", "cron_mode") == "approve"
raise unless config.dig("security", "redact_secrets") == true
raise if config["model"].key?("base_url")
RUBY

grep -q 'github("ramziddin/personal-agent", { branch: "main" })' .railway/railway.ts
grep -q '"/opt/data": volume("hermes-data")' .railway/railway.ts
grep -q 'GLM_API_KEY: preserve()' .railway/railway.ts
grep -q 'TELEGRAM_BOT_TOKEN: preserve()' .railway/railway.ts
grep -q 'docker run --rm personal-agent:test --version' .github/workflows/ci.yml

if grep -E '[0-9]{8,}:[A-Za-z0-9_-]{20,}|sk-[A-Za-z0-9_-]{16,}' .env.example >/dev/null; then
  printf '%s\n' '.env.example appears to contain a real credential' >&2
  exit 1
fi

printf '%s\n' 'repository test passed'
