up:
	@docker compose up -d

down:
	@docker compose down

restart:
	@docker compose restart

logs:
	@docker compose logs

ps:
	@docker compose ps

upload:
	@./upload.sh

PHONY: up down restart logs ps upload
