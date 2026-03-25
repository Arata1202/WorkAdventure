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

define REQUIRED_P_AWS_OR_AZURE
	@set -e; \
	if [ -z "$(strip $(P))" ]; then \
		echo ""; \
		echo "ERROR: Missing required P."; \
		echo "Usage: make $(MAKECMDGOALS) P=aws|azure"; \
		exit 1; \
	fi; \
	if [ "$(P)" != "aws" ] && [ "$(P)" != "azure" ]; then \
		echo ""; \
		echo "ERROR: P must be aws or azure."; \
		echo "Usage: make $(MAKECMDGOALS) P=aws|azure"; \
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

# SSM

ssm:
	@aws ssm start-session --target ${EC2_INSTANCE_ID}

# SSH

ifeq ($(P),aws)
SSH_KEY_PATH := $(EC2_SSH_KEY_PATH)
PUBLIC_IPV4_ADDRESS := $(EC2_PUBLIC_IPV4_ADDRESS)
else ifeq ($(P),azure)
SSH_KEY_PATH := $(AZURE_SSH_KEY_PATH)
PUBLIC_IPV4_ADDRESS := $(AZURE_PUBLIC_IPV4_ADDRESS)
endif

SSH := ssh -i $(SSH_KEY_PATH) -o StrictHostKeyChecking=accept-new ubuntu@$(PUBLIC_IPV4_ADDRESS)

ssh:
	$(REQUIRED_P_AWS_OR_AZURE)
	@$(SSH)

rsync:
	$(REQUIRED_P_AWS_OR_AZURE)
	@set -e; \
	echo ""; \
	echo "== (review changes) =="; \
	echo ""; \
	rsync -avz --dry-run --itemize-changes --filter='merge .rsyncignore' -e "ssh -i $(SSH_KEY_PATH) -o StrictHostKeyChecking=accept-new" ./ ubuntu@$(PUBLIC_IPV4_ADDRESS):~/WorkAdventure/; \
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
	rsync -avz --filter='merge .rsyncignore' -e "ssh -i $(SSH_KEY_PATH) -o StrictHostKeyChecking=accept-new" ./ ubuntu@$(PUBLIC_IPV4_ADDRESS):~/WorkAdventure/

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

tf-init:
	${REQUIRED_P_AWS_OR_AZURE}
	@cd terraform/${P} && terraform init

tf-plan:
	${REQUIRED_P_AWS_OR_AZURE}
	@cd terraform/${P} && terraform plan

tf-apply:
	${REQUIRED_P_AWS_OR_AZURE}
	@cd terraform/${P} && terraform apply

tf-destroy:
	${REQUIRED_P_AWS_OR_AZURE}
	@cd terraform/${P} && terraform destroy

# WorkAdventure

wa-init:
	@npm install && cd maps && npm install

wa-update:
	@./scripts/wa-update.sh

wa-dev:
	@cd maps && ${DR} npm run dev

wa-upload:
	@cd maps && ${DR} npm run upload

.PHONY: ssm ssh rsync exec up up-f stop restart logs ps encrypt decrypt tf-init tf-plan tf-apply tf-destroy wa-init wa-update wa-dev wa-upload
