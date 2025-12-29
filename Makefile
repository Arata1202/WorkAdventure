up:
	@dotenvx run -- docker compose up -d

down:
	@dotenvx run -- docker compose down

restart:
	@dotenvx run -- docker compose down
	@dotenvx run -- docker compose up -d

logs:
	@dotenvx run -- docker compose logs

ps:
	@dotenvx run -- docker compose ps -a

upload:
	@cd map-starter-kit-master && dotenvx run -- npm run upload

.PHONY: up down restart logs ps upload
