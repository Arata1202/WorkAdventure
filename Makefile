P ?=

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

init:
	@npm install && cd maps && npm install

# SSH

ssh:
	@ssh -i $(EC2_SSH_KEY_PATH) -o StrictHostKeyChecking=accept-new ubuntu@$(EC2_PUBLIC_IPV4_ADDRESS)

rsync:
	@set -e; \
	echo ""; \
	echo "== (review changes) =="; \
	echo ""; \
	rsync -avz --dry-run --itemize-changes --filter='merge .rsyncignore' -e "ssh -i $(EC2_SSH_KEY_PATH) -o StrictHostKeyChecking=accept-new" ./ ubuntu@$(EC2_PUBLIC_IPV4_ADDRESS):~/WorkAdventure/; \
	echo ""; \
	printf "Proceed with rsync? [y/N] "; \
	read ans; \
	echo ""; \
	case "$$ans" in \
		y|Y|yes|YES) ;; \
		*) echo "Aborted"; exit 1 ;; \
	esac; \
	echo "== (result) =="; \
	echo ""; \
	rsync -avz --filter='merge .rsyncignore' -e "ssh -i $(EC2_SSH_KEY_PATH) -o StrictHostKeyChecking=accept-new" ./ ubuntu@$(EC2_PUBLIC_IPV4_ADDRESS):~/WorkAdventure/

meta:
	@ssh -i $(EC2_SSH_KEY_PATH) -o StrictHostKeyChecking=accept-new ubuntu@$(EC2_PUBLIC_IPV4_ADDRESS) "cat ~/WorkAdventure/egress/logs/meta.jsonl"

# Docker

up:
	$(OPTIONAL_P)
	@npx dotenvx run -- docker compose up -d $(P)

up-f:
	$(OPTIONAL_P)
	@npx dotenvx run -- docker compose up -d --force-recreate $(P)

up-b:
	$(OPTIONAL_P)
	@npx dotenvx run -- docker compose up -d --build $(P)

stop:
	$(OPTIONAL_P)
	@npx dotenvx run -- docker compose stop $(P)

restart:
	$(OPTIONAL_P)
	@npx dotenvx run -- docker compose stop $(P)
	@npx dotenvx run -- docker compose up -d $(P)

logs:
	$(OPTIONAL_P)
	@npx dotenvx run -- docker compose logs -f $(P)

ps:
	$(OPTIONAL_P)
	@npx dotenvx run -- docker compose ps -a $(P)

# Dotenvx

encrypt:
	@npx dotenvx encrypt

decrypt:
	@npx dotenvx decrypt

# Terraform

apply:
	@cd terraform && terraform apply

# WorkAdventure

wa-dev:
	@cd maps && npx dotenvx run -- npm run dev

wa-upload:
	@cd maps && npx dotenvx run -- npm run upload

# LiveKit

lk-room-list:
	@npx dotenvx run -- lk room list --url http://localhost:7880

lk-egress-list:
	@npx dotenvx run -- lk egress list --url http://localhost:7880

lk-egress-start:
	$(REQUIRED_P)
	@npx dotenvx run -- ./egress/bin/start.sh $(P)

.PHONY: init ssh rsync meta up up-f up-b stop restart logs ps encrypt decrypt apply wa-dev wa-upload lk-room-list lk-egress-list lk-egress-start
