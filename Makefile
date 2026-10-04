.PHONY: up build view down
up:
	bash scripts/bootstrap.sh
build:
	python3 scripts/run-job.py
view:
	bash scripts/view-app.sh
down:
	bash scripts/cleanup.sh
