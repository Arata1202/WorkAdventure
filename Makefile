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

# SSH

SSH := ssh -i $(EC2_SSH_KEY_PATH) -o StrictHostKeyChecking=accept-new ubuntu@$(EC2_PUBLIC_IPV4_ADDRESS)

ssh:
	@$(SSH)

ssh-git-pull:
	@$(SSH) "cd ~/WorkAdventure && git pull"

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

# Docker

DC:=docker compose

exec:
	$(REQUIRED_P)
	@${DR} ${DC} exec $(P) bash

up:
	$(OPTIONAL_P)
	@${DR} ${DC} up -d $(P)

up-f:
	$(OPTIONAL_P)
	@${DR} ${DC} up -d --force-recreate $(P)

up-b:
	$(OPTIONAL_P)
	@${DR} ${DC} up -d --build $(P)

stop:
	$(OPTIONAL_P)
	@${DR} ${DC} stop $(P)

restart:
	$(OPTIONAL_P)
	@${DR} ${DC} stop $(P)
	@${DR} ${DC} up -d $(P)

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

# Terraform

apply:
	@cd terraform/aws && terraform apply

# WorkAdventure

wa-init:
	@npm install && cd maps && npm install

wa-update:
	@./scripts/wa-update.sh

wa-dev:
	@cd maps && ${DR} npm run dev

wa-upload:
	@cd maps && ${DR} npm run upload

# LiveKit

lk-room-list:
	@${DR} ${DC} exec webhook bash -c 'lk room list'

lk-egress-list:
	@${DR} ${DC} exec webhook bash -c 'lk egress list'

.PHONY: ssh ssh-git-pull rsync exec up up-f up-b stop restart logs ps encrypt decrypt apply wa-init wa-update wa-dev wa-upload lk-room-list lk-egress-list
