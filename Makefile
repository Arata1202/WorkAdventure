up:
	@docker compose up -d

down:
	@docker compose down

restart:
	@docker compose down
	@docker compose up -d

logs:
	@docker compose logs

ps:
	@docker compose ps -a

upload:
	@./upload.sh

PHONY: up down restart logs ps upload
