# Keycloak Development Setup

Production-ready Keycloak setup for development and testing with disabled security features.

## Quick Start

The Make targets auto-detect Docker Compose (prefers `docker compose`, falls back to `docker-compose`). Use whichever command is available if you run things manually.

### Option 1: Using setup script (Recommended)
```bash
chmod +x setup.sh
./setup.sh
```

### Option 2: Using Makefile
```bash
make setup
```

### Option 3: Manual
```bash
# Create import directory and copy configs
mkdir -p keycloak/import
cp dev-realm.json keycloak/import/

# Start services
docker compose up -d  # or docker-compose

# Check health
docker compose ps

# Verify import
docker compose logs keycloak | grep -i import
```

## Access

- **Keycloak Admin Console**: http://localhost:8080
  - Username: `admin`
  - Password: `admin`

- **Realm**: `dev`
- **Admin Console Realm URL**: http://localhost:8080/admin/master/console/#/dev

## Pre-configured Users

### Test User
- Username: `testuser`
- Password: `test123`
- Email: `test@example.com`
- Roles: `user`

### Admin User
- Username: `admin`
- Password: `admin123`
- Email: `admin@example.com`
- Roles: `admin`, `user`

## Pre-configured Clients

### dev-client (Public Client)
- **Client ID**: `dev-client`
- **Type**: Public (for frontend apps)
- **Flows**: Authorization Code, Implicit, Direct Access
- **Redirect URIs**: `http://localhost:*`
- **Web Origins**: `*`

### dev-service (Service Account)
- **Client ID**: `dev-service`
- **Type**: Confidential (for backend services)
- **Secret**: `dev-secret-123`
- **Flows**: Service Account, Direct Access

### backend-svc (Service Account)
- **Client ID**: `backend-svc`
- **Type**: Confidential (for inter-service calls)
- **Secret**: `dev-backend-secret-123` in `dev` realm (`test-backend-secret-123` / `prod-backend-secret-123` in respective realms)
- **Flows**: Service Account, Client Credentials

## Configuration Details

### Security Settings (Disabled for Dev)
- SSL: Not required
- Email verification: Disabled
- Brute force protection: Disabled
- Registration: Enabled

### Token Lifespans (Extended for Dev)
- Access token: 10 hours
- SSO session: 10 hours
- Refresh token: 30 days

## Testing Token Generation

### Public Client (Password Grant)
```bash
curl -X POST http://localhost:8080/realms/dev/protocol/openid-connect/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "client_id=dev-client" \
  -d "username=testuser" \
  -d "password=test123" \
  -d "grant_type=password"
```

### Service Account (Client Credentials)
```bash
curl -X POST http://localhost:8080/realms/dev/protocol/openid-connect/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "client_id=dev-service" \
  -d "client_secret=dev-secret-123" \
  -d "grant_type=client_credentials"
```

### Backend service account (Client Credentials)
```bash
curl -X POST http://localhost:8080/realms/dev/protocol/openid-connect/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "client_id=backend-svc" \
  -d "client_secret=dev-backend-secret-123" \
  -d "grant_type=client_credentials"
```

## Useful Endpoints

- **Well-known Config**: http://localhost:8080/realms/dev/.well-known/openid-configuration
- **Token Endpoint**: http://localhost:8080/realms/dev/protocol/openid-connect/token
- **UserInfo**: http://localhost:8080/realms/dev/protocol/openid-connect/userinfo
- **Logout**: http://localhost:8080/realms/dev/protocol/openid-connect/logout
- **Health Check**: http://localhost:8080/health/ready
- **Metrics**: http://localhost:8080/metrics

## File Structure

```
.
├── compose.yaml
└── keycloak/
    └── import/
        ├── dev-realm.json
        ├── test-realm.json (optional)
        └── prod-realm.json (optional)
```

## How Realm Import Works

Keycloak automatically imports all JSON files from `/opt/keycloak/data/import` on startup:

1. **Volume Mount**: `./keycloak/import:/opt/keycloak/data/import:ro`
   - Maps local `keycloak/import/` to container import directory
   - `:ro` = read-only for security

2. **Import Flag**: `--import-realm` in command
   - Triggers automatic import on startup
   - Processes all `.json` files in import directory

3. **File Naming**: Any `.json` file works
   - `dev-realm.json` - development realm
   - `test-realm.json` - testing realm
   - Multiple files = multiple realms imported

4. **Import Behavior**:
   - Only imports if realm doesn't exist
   - Won't overwrite existing realms
   - To re-import: delete realm via admin console or drop database

## Commands

### Using Makefile
```bash
make setup       # Setup and start
make up          # Start services
make down        # Stop services
make restart     # Restart Keycloak
make logs        # View logs
make clean       # Remove all data
make test-token  # Get test token
```

### Using Docker Compose
```bash
# Start
docker compose up -d  # or docker-compose

# Stop
docker compose down

# Remove all data
docker compose down -v

# View logs
docker compose logs -f keycloak

# Restart Keycloak
docker compose restart keycloak
```

## Notes

⚠️ **This configuration is for development only**. Never use in production:
- No SSL/TLS enforcement
- Weak passwords
- Wildcard CORS origins
- Extended token lifespans
- Disabled security features

## Troubleshooting

### Keycloak won't start
```bash
# Check PostgreSQL is healthy
docker compose logs postgres

# Check Keycloak logs
docker compose logs keycloak
```

### Realm not imported
- Ensure JSON files are in `keycloak/import/` directory
- Check file permissions (must be readable)
- Verify JSON syntax: `cat keycloak/import/dev-realm.json | jq`
- Check import logs: `docker compose logs keycloak | grep -i import`
- If realm exists, it won't be re-imported (drop DB or delete realm)

### Connection refused
- Wait 30-60 seconds after startup
- Check health: `curl http://localhost:8080/health/ready`
