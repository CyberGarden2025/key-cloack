.PHONY: setup up down restart logs clean test-token help

help:
	@echo "Keycloak Development Environment"
	@echo ""
	@echo "Available commands:"
	@echo "  make setup       - Setup and start Keycloak"
	@echo "  make up          - Start services"
	@echo "  make down        - Stop services"
	@echo "  make restart     - Restart Keycloak"
	@echo "  make logs        - View Keycloak logs"
	@echo "  make clean       - Stop and remove all data"
	@echo "  make test-token  - Get test token"
	@echo "  make help        - Show this help"

setup:
	@mkdir -p keycloak/import
	@if [ ! -f keycloak/import/dev-realm.json ]; then \
		echo "Copying realm config..."; \
		cp dev-realm.json keycloak/import/ 2>/dev/null || echo "Place dev-realm.json in keycloak/import/"; \
	fi
	@docker-compose up -d
	@echo "Waiting for Keycloak..."
	@timeout 180 bash -c 'until curl -sf http://localhost:8080/health/ready > /dev/null 2>&1; do sleep 5; done' || echo "Timeout - check logs"
	@echo "Keycloak is ready at http://localhost:8080"

up:
	@docker-compose up -d
	@docker-compose ps

down:
	@docker-compose down

restart:
	@docker-compose restart keycloak

logs:
	@docker-compose logs -f keycloak

clean:
	@docker-compose down -v
	@echo "All data removed"

test-token:
	@echo "Getting token for testuser..."
	@curl -s -X POST http://localhost:8080/realms/dev/protocol/openid-connect/token \
		-H "Content-Type: application/x-www-form-urlencoded" \
		-d "client_id=dev-client" \
		-d "username=testuser" \
		-d "password=test123" \
		-d "grant_type=password" | jq -r '.access_token' | head -c 50
	@echo "..."