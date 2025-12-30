C ?=

# Docker

up:
	@npx dotenvx run -- docker compose up -d $(C)

stop:
	@npx dotenvx run -- docker compose stop $(C)

restart:
	@npx dotenvx run -- docker compose stop $(C)
	@npx dotenvx run -- docker compose up -d $(C)

logs:
	@npx dotenvx run -- docker compose logs -f $(C)

ps:
	@npx dotenvx run -- docker compose ps -a $(C)

# Dotenvx

encrypt:
	@npx dotenvx encrypt

decrypt:
	@npx dotenvx decrypt

.PHONY: up stop restart logs ps encrypt decrypt
