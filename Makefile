P ?=

# Docker

up:
	@npx dotenvx run -- docker compose up -d $(P)

up-f:
	@npx dotenvx run -- docker compose up -d --force-recreate $(P)

stop:
	@npx dotenvx run -- docker compose stop $(P)

restart:
	@npx dotenvx run -- docker compose stop $(P)
	@npx dotenvx run -- docker compose up -d $(P)

logs:
	@npx dotenvx run -- docker compose logs -f $(P)

ps:
	@npx dotenvx run -- docker compose ps -a $(P)

# Dotenvx

encrypt:
	@npx dotenvx encrypt

decrypt:
	@npx dotenvx decrypt

# LiveKit

lk-room-list:
	@npx dotenvx run -- lk room list --url http://localhost:7880

lk-egress-list:
	@npx dotenvx run -- lk egress list --url http://localhost:7880

lk-egress-start:
	@npx dotenvx run -- ./egress/bin/start.sh $(P)

lk-egress-stop:
	@npx dotenvx run -- ./egress/bin/stop.sh $(P)

.PHONY: up up-f stop restart logs ps encrypt decrypt lk-room-list lk-egress-list lk-egress-start lk-egress-stop
