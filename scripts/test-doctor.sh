#!/usr/bin/env bash
# Offline regression: failed commands must not become healthy empty output.
set -euo pipefail
repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fixture_dir="$(mktemp -d)"
trap 'rm -rf -- "$fixture_dir"' EXIT
cat > "$fixture_dir/probe" <<'SH'
#!/usr/bin/env bash
case "$(basename "$0"):$*" in
  'brew:--version') echo 'Homebrew fixture' ;;
  'brew:doctor') echo 'Your system is ready to brew'; exit 76 ;;
  brew:bundle*) exit 72 ;;
  'mise:--version') echo 'mise fixture' ;;
  'mise:doctor') exit 73 ;;
  'chezmoi:--version') echo 'chezmoi version fixture' ;;
  'chezmoi:source-path') echo "$FIXTURE_REPO" ;;
  chezmoi:status*) exit 74 ;;
  'chezmoi:doctor') exit 75 ;;
  timeout:*|ssh:*) echo 'successfully authenticated' ;;
  *) exit 0 ;;
esac
SH
chmod +x "$fixture_dir/probe"
for tool in brew mise chezmoi sw_vers ssh timeout; do
  cp "$fixture_dir/probe" "$fixture_dir/$tool"
done
set +e
output="$(PATH="$fixture_dir:$PATH" FIXTURE_REPO="$repo_dir" bash "$repo_dir/scripts/doctor.sh" 2>&1)"
result=$?
set -e
[ "$result" -ne 0 ] || { echo 'doctor incorrectly passed'; exit 1; }
for expected in \
  'brew doctor failed (exit 76' \
  'Brewfile check failed (exit 72' \
  'mise doctor failed (exit 73' \
  'chezmoi status failed (exit 74' \
  'chezmoi doctor failed (exit 75'; do
  grep -Fq "$expected" <<< "$output" || { echo "missing failure: $expected"; exit 1; }
done
if grep -Fq 'chezmoi status (no-op' <<< "$output"; then
  echo 'failed status incorrectly treated as no-op'; exit 1
fi
echo 'PASS doctor preserves brew/mise/chezmoi failures'
