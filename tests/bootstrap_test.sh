#!/bin/sh
set -eu

test_root="$(mktemp -d)"
trap 'rm -rf "$test_root"' EXIT INT TERM

bootstrap_source="$test_root/source"
hermes_home="$test_root/data"
fake_bin="$test_root/bin"
mkdir -p "$bootstrap_source" "$hermes_home/memories" "$hermes_home/sessions" "$hermes_home/skills" "$fake_bin"

printf '%s\n' 'model: new-config' > "$bootstrap_source/config.yaml"
printf '%s\n' '# New public persona' > "$bootstrap_source/SOUL.md"
printf '%s\n' 'model: old-config' > "$hermes_home/config.yaml"
printf '%s\n' '# Old persona' > "$hermes_home/SOUL.md"
printf '%s\n' 'private memory' > "$hermes_home/memories/MEMORY.md"
printf '%s\n' 'private session' > "$hermes_home/sessions/session.json"
printf '%s\n' 'learned skill' > "$hermes_home/skills/learned.md"

cat > "$fake_bin/hermes" <<'EOF'
#!/bin/sh
printf '%s\n' "$*" > "$HERMES_TEST_COMMAND_LOG"
EOF
chmod +x "$fake_bin/hermes"

PATH="$fake_bin:$PATH" \
HERMES_HOME="$hermes_home" \
HERMES_BOOTSTRAP_SOURCE="$bootstrap_source" \
HERMES_TEST_COMMAND_LOG="$test_root/command.log" \
  sh scripts/bootstrap.sh

assert_file_contains() {
  file="$1"
  expected="$2"
  actual="$(cat "$file")"
  if [ "$actual" != "$expected" ]; then
    printf 'Expected %s to contain "%s", got "%s"\n' "$file" "$expected" "$actual" >&2
    exit 1
  fi
}

assert_file_contains "$hermes_home/config.yaml" 'model: new-config'
assert_file_contains "$hermes_home/SOUL.md" '# New public persona'
assert_file_contains "$hermes_home/memories/MEMORY.md" 'private memory'
assert_file_contains "$hermes_home/sessions/session.json" 'private session'
assert_file_contains "$hermes_home/skills/learned.md" 'learned skill'
assert_file_contains "$test_root/command.log" 'gateway run'

test -d "$hermes_home/workspace"
test "$(find "$hermes_home" -maxdepth 1 -name '.bootstrap-*' -print | wc -l | tr -d ' ')" = '0'

incomplete_source="$test_root/incomplete-source"
incomplete_home="$test_root/incomplete-data"
mkdir -p "$incomplete_source" "$incomplete_home"
printf '%s\n' 'model: incomplete-config' > "$incomplete_source/config.yaml"
printf '%s\n' 'model: retained-config' > "$incomplete_home/config.yaml"
printf '%s\n' '# Retained persona' > "$incomplete_home/SOUL.md"

if PATH="$fake_bin:$PATH" \
  HERMES_HOME="$incomplete_home" \
  HERMES_BOOTSTRAP_SOURCE="$incomplete_source" \
  HERMES_TEST_COMMAND_LOG="$test_root/incomplete-command.log" \
    sh scripts/bootstrap.sh 2>/dev/null; then
  printf '%s\n' 'Expected bootstrap to reject an incomplete public source' >&2
  exit 1
fi

assert_file_contains "$incomplete_home/config.yaml" 'model: retained-config'
assert_file_contains "$incomplete_home/SOUL.md" '# Retained persona'
test ! -e "$test_root/incomplete-command.log"

printf '%s\n' 'bootstrap test passed'
