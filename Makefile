# AutoLabel Makefile
.PHONY: build up down pull-model label search

build:
	docker compose build

up:
	docker compose up -d
	@echo "API: http://localhost:8000/docs"
	@echo "UI:  http://localhost:7860"

down:
	docker compose down

pull-model:
	docker compose exec ollama ollama pull llava:7b

# Usage: make label DESC="label animals" FOLDER="/data/images"
label:
	curl -X POST http://localhost:8000/label \
	  -H 'Content-Type: application/json' \
	  -d '{"description": "$(DESC)", "image_folder": "$(FOLDER)"}'

logs:
	docker compose logs -f autolabel-api
