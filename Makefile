up:
	@docker compose up -d

down:
	@docker compose down

upload:
	@./upload.sh

PHONY: up down upload
