#!/usr/bin/env bash

set -euo pipefail

PATH="${HOME}/.local/bin:/usr/local/bin:/opt/homebrew/bin:${PATH}"
export PATH

section() {
	printf '\n== %s ==\n' "$1"
}

ok() {
	printf '[OK] %s\n' "$1"
}

fail() {
	printf '[FAIL] %s\n' "$1"
	printf '       %s\n' "$2"
	exit 1
}

check_direct() {
	local label="$1"
	shift

	local output
	if output="$("$@" 2>&1)"; then
		ok "$label"
		return 0
	fi

	fail "$label" "$output"
}

check_asdf() {
	local label="$1"
	shift

	local output
	if output="$(asdf exec "$@" 2>&1)"; then
		ok "$label"
		return 0
	fi

	fail "$label" "$output"
}

check_port_selector() {
	local output
	local port

	if ! output="$(port-selector --name ci-smoke 2>&1)"; then
		fail "port-selector returns a free port" "$output"
	fi

	port="$(printf '%s\n' "$output" | awk '/^[[:space:]]*[0-9]+[[:space:]]*$/ { gsub(/[[:space:]]/, "", $0); port=$0 } END { print port }')"

	if [ -z "$port" ]; then
		fail "port-selector returns a free port" "$output"
	fi

	ok "port-selector returns a free port"
	port-selector --forget --name ci-smoke >/dev/null 2>&1 || true
}

section "Bootstrap"
check_direct "asdf installed" asdf version

section "Core toolchain"
check_asdf "direnv installed" direnv version
check_asdf "gh installed" gh --version
check_asdf "gitleaks installed" gitleaks version
check_asdf "jq installed" jq --version
check_asdf "node installed" node --version
check_asdf "npm installed" npm --version
check_asdf "npx installed" npx --version
check_port_selector
check_asdf "ruby installed" ruby --version
check_asdf "tmux installed" tmux -V
check_asdf "yarn installed" yarn --version
check_asdf "zellij installed" zellij --version

section "Agent CLIs"
check_asdf "claude installed" claude --version
check_asdf "codex installed" codex --version
check_asdf "playwright-cli installed" playwright-cli --version
check_direct "ccbox installed" ccbox --version

printf '\nCI smoke checks passed.\n'
