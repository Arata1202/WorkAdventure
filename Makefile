DR := npx dotenvx run --

define REQUIRED_P
	@set -e; \
	if [ -z "$(strip $(P))" ]; then \
		echo ""; \
		echo "ERROR: Missing required P."; \
		echo "Usage: make $(MAKECMDGOALS) P=<TARGET>"; \
		exit 1; \
	fi
endef

define OPTIONAL_P
	@set -e; \
	if [ -z "$(strip $(P))" ]; then \
		echo ""; \
		echo "WARN: P is empty. This will run on ALL services."; \
		echo "Tip: make $(MAKECMDGOALS) P=<TARGET>"; \
		echo ""; \
		printf "Proceed? [y/N] "; \
		read ans; \
		echo ""; \
		case "$$ans" in \
			y|Y|yes|YES) ;; \
			*) echo "Aborted"; exit 1 ;; \
		esac; \
	fi
endef

# Docker

DC := docker compose

exec:
	$(REQUIRED_P)
	@${DR} ${DC} exec $(P) bash

up:
	$(OPTIONAL_P)
	@${DR} ${DC} up -d $(P)

up-f:
	$(OPTIONAL_P)
	@${DR} ${DC} up -d --force-recreate $(P)

stop:
	$(OPTIONAL_P)
	@${DR} ${DC} stop $(P)

restart:
	$(OPTIONAL_P)
	@${DR} ${DC} restart $(P)

logs:
	$(OPTIONAL_P)
	@${DR} ${DC} logs -f $(P)

ps:
	$(OPTIONAL_P)
	@${DR} ${DC} ps -a $(P)

# Dotenvx

encrypt:
	@npx dotenvx encrypt

decrypt:
	@npx dotenvx decrypt

# WorkAdventure

wa-init:
	@npm install && cd maps && npm install

wa-dev:
	@cd maps && ${DR} npm run dev

wa-upload:
	@cd maps && ${DR} npm run upload

.PHONY: exec up up-f stop restart logs ps encrypt decrypt wa-init wa-dev wa-upload
