# AI agents, CLI tools, skills, and plugins

BLUE := \033[0;34m
NC := \033[0m
PATH := $(HOME)/.asdf/shims:$(HOME)/.local/bin:/usr/local/bin:/opt/homebrew/bin:$(PATH)
VERSION ?= 0.2.0

NPM ?= npm
CLAUDE ?= claude
SKILLS_NPX ?= npx
SKILLS ?= $(SKILLS_NPX) skills
AGENTS_TARGETS := codex claude-code
AGENTS_SKILLS_AGENT_FLAGS := $(foreach agent,$(AGENTS_TARGETS),-a $(agent))
CLAUDE_MARKETPLACE_NAMES ?= dapi
CLAUDE_PLUGIN_NAMESPACE ?= dapi

REGISTRY_REPO ?= thinknetica/ai_swe_group_1

GOOGLE_WORKSPACE_SKILLS := \
	gws-docs \
	gws-docs-write \
	gws-drive \
	gws-sheets

.PHONY: ai bootstrap asdf-package asdf-install version check extra extra-check check-context codex-context register
.PHONY: agents-install agents agents-cli agents-skills extra-skills
.PHONY: agents-skills-install agents-skills-list agents-skills-check-npx

ai: bootstrap
	@$(MAKE) agents-install

bootstrap: asdf-package asdf-install

version:
	@version="$(VERSION)"; \
	if printf '%s' "$$version" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+([.-][0-9A-Za-z.-]+)?([+][0-9A-Za-z.-]+)?$$'; then \
		printf '%s\n' "$$version"; \
	else \
		echo "❌ VERSION must contain a semver value" >&2; \
		exit 1; \
	fi

check:
	@VERSION=$(VERSION) ./scripts/test-setup.sh

extra-check:
	@CLAUDE_MARKETPLACE_NAMES="$(CLAUDE_MARKETPLACE_NAMES)" \
	CLAUDE_EXPECTED_PLUGINS="$(CLAUDE_PLUGINS)" \
	./scripts/test-extras.sh

check-context:
	@./scripts/test-context.sh

codex-context:
	@./scripts/codex-context.sh

asdf-package:
	@set -e; \
	if command -v asdf > /dev/null 2>&1; then \
		echo "Install asdf - already exists"; \
	elif command -v brew > /dev/null 2>&1; then \
		brew install asdf; \
		echo "Install asdf - installed via brew"; \
	elif command -v git > /dev/null 2>&1; then \
		git clone https://github.com/asdf-vm/asdf.git "$(HOME)/.asdf" --branch v0.16.7; \
		echo "Install asdf - installed via git to $(HOME)/.asdf"; \
		echo "⚠️  Add asdf to your shell: https://asdf-vm.com/guide/getting-started.html"; \
	else \
		echo "Install asdf - failed: need either brew or git to install asdf"; \
		exit 1; \
	fi

asdf-install: asdf-package
	@echo "Install asdf plugins and tools"
	@asdf plugin add nodejs || true
	@asdf plugin add ruby || true
	@asdf plugin add direnv || true
	@asdf plugin add github-cli || true
	@asdf plugin add gitleaks || true
	@asdf plugin add jq || true
	@asdf install
	@if ! command -v port-selector > /dev/null 2>&1; then \
		if command -v brew > /dev/null 2>&1; then \
			brew install dapi/tap/port-selector 2>/dev/null || \
			(curl -fsSL https://github.com/dapi/port-selector/releases/latest/download/port-selector-$$(uname -s | tr '[:upper:]' '[:lower:]')-$$(uname -m) -o "$(HOME)/.local/bin/port-selector" && chmod +x "$(HOME)/.local/bin/port-selector"); \
		elif command -v curl > /dev/null 2>&1; then \
			mkdir -p "$(HOME)/.local/bin"; \
			curl -fsSL https://github.com/dapi/port-selector/releases/latest/download/port-selector-$$(uname -s | tr '[:upper:]' '[:lower:]')-$$(uname -m) -o "$(HOME)/.local/bin/port-selector" && chmod +x "$(HOME)/.local/bin/port-selector"; \
		fi; \
		echo "Install port-selector - done"; \
	else \
		echo "Install port-selector - already exists"; \
	fi

agents-install: agents agents-cli agents-skills

# --- AI Agents ---

agents:
	@$(NPM) install -g @anthropic-ai/claude-code
	@$(NPM) install -g @openai/codex

# --- CLI tools used by agents ---

agents-cli:
	@$(NPM) install -g @playwright/cli@latest
	@if command -v ccbox >/dev/null 2>&1; then \
		echo "Install ccbox - already exists"; \
	elif command -v brew >/dev/null 2>&1; then \
		brew tap diskd-ai/ccbox && brew install ccbox; \
		echo "Install ccbox - installed via brew"; \
	elif command -v curl >/dev/null 2>&1; then \
		curl -fsSL -H 'Cache-Control: no-cache' -o - https://raw.githubusercontent.com/diskd-ai/ccbox/main/scripts/install.sh | /bin/bash; \
		echo "Install ccbox - installed via script"; \
	else \
		echo "⚠️  ccbox: need either brew or curl to install"; \
	fi

# --- Skills for agents ---

agents-skills: agents-skills-install

agents-skills-check-npx:
	@$(SKILLS_NPX) --version >/dev/null 2>&1 || (echo "❌ npx not available. Run 'make ai' after bootstrap installs Node.js." && exit 1)

agents-skills-install: agents-skills-check-npx
	@echo "$(BLUE)📦 Installing core skills...$(NC)"
	@for dir in "$$HOME/.claude/skills" "$$HOME/.codex/skills"; do \
		if [ -d "$$dir/prompt-engeneering" ]; then \
			echo "  🗑️  Removing old prompt-engeneering (typo) from $$dir"; \
			rm -rf "$$dir/prompt-engeneering"; \
		fi; \
	done
	@echo "  📥 Installing playwright-cli from microsoft/playwright-cli"
	@$(SKILLS) add microsoft/playwright-cli --skill playwright-cli -g $(AGENTS_SKILLS_AGENT_FLAGS) -y
	@echo "  📥 Installing prompt-engineering from CodeAlive-AI/prompt-engineering-skill"
	@$(SKILLS) add CodeAlive-AI/prompt-engineering-skill@prompt-engineering -g -y
	@echo "  📥 Installing ccbox from diskd-ai/ccbox"
	@$(SKILLS) add diskd-ai/ccbox --skill ccbox -g $(AGENTS_SKILLS_AGENT_FLAGS) -y
	@echo "  📥 Installing ccbox-insights from diskd-ai/ccbox"
	@$(SKILLS) add diskd-ai/ccbox --skill ccbox-insights -g $(AGENTS_SKILLS_AGENT_FLAGS) -y

agents-skills-list:
	@echo "$(BLUE)📋 Core skills:$(NC)"
	@printf "  playwright-cli (microsoft/playwright-cli)\n"
	@printf "  prompt-engineering (CodeAlive-AI/prompt-engineering-skill)\n"
	@printf "  ccbox (diskd-ai/ccbox)\n"
	@printf "  ccbox-insights (diskd-ai/ccbox)\n"

# --- Extra skills and plugins (not installed by default) ---

extra: extra-skills

extra-skills: agents-skills-check-npx
	@echo "$(BLUE)📦 Installing extra CLIs, skills, and plugins...$(NC)"
	@if command -v brew > /dev/null 2>&1; then \
		brew install pimalaya/pimalaya/himalaya 2>/dev/null || echo "⚠️  himalaya: install manually from https://github.com/pimalaya/himalaya/releases"; \
	elif command -v curl > /dev/null 2>&1; then \
		mkdir -p "$(HOME)/.local/bin"; \
		curl -fsSL https://raw.githubusercontent.com/pimalaya/himalaya/master/install.sh | sh -s -- --dest "$(HOME)/.local/bin"; \
	else \
		echo "⚠️  himalaya: need brew or curl — install manually from https://github.com/pimalaya/himalaya/releases"; \
	fi
	@$(NPM) install -g @dapi/tgcli
	@$(NPM) install -g @googleworkspace/cli
	@echo "  📥 Installing tgcli from dapi/tgcli"
	@$(SKILLS) add dapi/tgcli --skill tgcli -g $(AGENTS_SKILLS_AGENT_FLAGS) -y
	@for skill in $(GOOGLE_WORKSPACE_SKILLS); do \
		echo "  📥 Installing $$skill from googleworkspace/cli"; \
		$(SKILLS) add googleworkspace/cli --skill "$$skill" -g $(AGENTS_SKILLS_AGENT_FLAGS) -y; \
	done
	@for mp in $(CLAUDE_PLUGINS_MARKETPLACES); do \
		echo "  Adding marketplace $$mp..."; \
		$(CLAUDE) plugins marketplace add $$mp; \
	done
	@for plugin in $(CLAUDE_PLUGINS); do \
		echo "  Installing plugin $$plugin..."; \
		$(CLAUDE) plugins install $$plugin; \
	done

CLAUDE_PLUGINS_MARKETPLACES ?= dapi/claude-code-marketplace

CLAUDE_PLUGINS ?= \
	himalaya@$(CLAUDE_PLUGIN_NAMESPACE) \
	pr-review-fix-loop@$(CLAUDE_PLUGIN_NAMESPACE) \
	spec-reviewer@$(CLAUDE_PLUGIN_NAMESPACE) \
	zellij-workflow@$(CLAUDE_PLUGIN_NAMESPACE)

# --- Registry ---

register:
	@REPO_URL=$$(git remote get-url origin | sed 's|git@github.com:|https://github.com/|;s|\.git$$||'); \
	TMPDIR=$$(mktemp -d); \
	BRANCH="register-$$(echo "$$REPO_URL" | sed 's|https://github.com/||;s|/|-|g;s|[^a-zA-Z0-9-]|-|g')"; \
	echo "📋 Registering $$REPO_URL in $(REGISTRY_REPO)..."; \
	gh repo fork "$(REGISTRY_REPO)" --clone --remote --default-branch-only 2>/dev/null || true; \
	FORK_REPO="$$(gh api user -q .login)/$$(basename $(REGISTRY_REPO))"; \
	git clone "https://github.com/$$FORK_REPO.git" "$$TMPDIR/registry" && \
	cd "$$TMPDIR/registry" && \
	git remote add upstream "https://github.com/$(REGISTRY_REPO).git" && \
	git fetch upstream main --quiet && \
	git checkout -b "$$BRANCH" upstream/main && \
	echo "$$REPO_URL" >> REGISTRY.txt && \
	git add REGISTRY.txt && \
	git commit -m "Register $$REPO_URL" && \
	git push -u origin "$$BRANCH" && \
	gh pr create \
		--repo "$(REGISTRY_REPO)" \
		--title "Register $$REPO_URL" \
		--body "Adding \`$$REPO_URL\` to the registry." \
		--base main; \
	rm -rf "$$TMPDIR"
