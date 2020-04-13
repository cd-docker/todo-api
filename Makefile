.PHONY: test release clean

export DOCKER_BUILDKIT=1
export COMPOSE_DOCKER_CLI_BUILD=1

test:
	${INFO} "Pulling latest images..."
	docker-compose pull
	${INFO} "Building images..."
	docker-compose build --pull release
	docker-compose build
	${INFO} "Running tests..."
	docker-compose up --abort-on-container-exit test
	${INFO} "Collecting test reports..."
	mkdir -p build
	test=$$(docker-compose ps -q test)
	docker cp $$test:/reports build
	${INFO} "Test stage complete"

release:
	${INFO} "Running database migrations..."
	docker-compose up --abort-on-container-exit migrate
	${INFO} "Collecting static files..."
	docker-compose run app python manage.py collectstatic --no-input
	${INFO} "Running acceptance tests..."
	docker-compose up --abort-on-container-exit acceptance
	${INFO} "Collecting test reports..."
	acceptance=$$(docker-compose ps -q acceptance)
	docker cp $$acceptance:/reports/acceptance.xml build/reports/acceptance.xml
	${INFO} "Release stage complete"

clean:
	${INFO} "Cleaning environment..."
	docker-compose down -v
	docker system prune --filter label=application=todobackend -f
	rm -rf build
	${INFO} "Clean stage complete"

# Recommended settings
.ONESHELL:
.SILENT:
SHELL=/bin/bash
.SHELLFLAGS = -ceo pipefail

# Cosmetics
YELLOW := "\e[1;33m"
RED := "\e[1;31m"
NC := "\e[0m"
INFO := @bash -c 'printf $(YELLOW); echo "=> $$0"; printf $(NC)'
ERROR := @bash -c 'printf $(RED); echo "ERROR: $$0"; printf $(NC); exit 1'