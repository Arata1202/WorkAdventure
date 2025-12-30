C ?=

# Docker

up:
	@dotenvx run -- docker compose up -d $(C)

stop:
	@dotenvx run -- docker compose stop $(C)

restart:
	@dotenvx run -- docker compose stop $(C)
	@dotenvx run -- docker compose up -d $(C)

logs:
	@dotenvx run -- docker compose logs -f $(C)

ps:
	@dotenvx run -- docker compose ps -a $(C)

# Dotenvx

encrypt:
	@dotenvx encrypt

decrypt:
	@dotenvx decrypt

.PHONY: up stop restart logs ps encrypt decrypt
