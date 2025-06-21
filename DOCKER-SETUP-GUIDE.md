# Unstract Docker Setup Guide

## 🚀 Quick Start (One Command Setup)

```bash
# Run this single command to set up and start Unstract
./setup-complete-env.sh && ./run-platform.sh
```

Once the services are up (about 30-60 seconds), visit http://frontend.unstract.localhost in your browser.

**Default Login Credentials:**
- Username: `unstract`
- Password: `unstract`

## 📋 Prerequisites

- Linux or macOS (Intel or M-series)
- Docker (20.10+)
- Docker Compose (2.0+)
- Python 3 (for environment setup)
- 8GB RAM minimum
- 10GB free disk space

## 🛠️ Detailed Setup Steps

### 1. Clone or Download the Repository

```bash
git clone https://github.com/Zipstack/unstract.git
cd unstract
```

### 2. Set Up Environment Files

Run the environment setup script:

```bash
./setup-complete-env.sh
```

This script will:
- Create all necessary `.env` files from samples
- Generate a secure encryption key
- Set up default credentials
- Configure all services

**⚠️ IMPORTANT**: Save the encryption key displayed by the script!

### 3. Start the Platform

```bash
./run-platform.sh
```

Options:
- `./run-platform.sh --build-local` - Build images locally
- `./run-platform.sh --update` - Update to latest version
- `./run-platform.sh -h` - Show all options

## 🔍 Verify Installation

### Check Service Status

```bash
docker compose -f docker/docker-compose.yaml ps
```

All services should show as "running" or "healthy".

### Access Points

- **Main Application**: http://frontend.unstract.localhost
- **API Documentation**: http://frontend.unstract.localhost/api/v1/docs
- **Traefik Dashboard**: http://localhost:8080
- **MinIO Console**: http://localhost:9001 (minioadmin/minioadmin)
- **RabbitMQ Management**: http://localhost:15672 (admin/password)
- **Qdrant Dashboard**: http://localhost:6333/dashboard

## 🐛 Troubleshooting

### Services Not Starting

1. Check Docker is running:
   ```bash
   docker info
   ```

2. Check for port conflicts:
   ```bash
   netstat -tulpn | grep -E '3000|8000|5432|6379|9000'
   ```

3. View logs:
   ```bash
   docker compose -f docker/docker-compose.yaml logs -f [service-name]
   ```

### "Configuring..." Message Stuck

1. Clear browser cache and cookies
2. Try incognito/private mode
3. Check backend logs:
   ```bash
   docker compose -f docker/docker-compose.yaml logs -f backend
   ```

### Cannot Upload Documents

1. Check MinIO is running:
   ```bash
   docker compose -f docker/docker-compose.yaml ps minio
   ```

2. Verify bucket creation:
   ```bash
   docker exec -it unstract-minio mc ls minio/unstract
   ```

### Database Connection Issues

1. Check PostgreSQL:
   ```bash
   docker exec -it unstract-db psql -U unstract_dev -d unstract_db -c "\dt"
   ```

2. Run migrations manually:
   ```bash
   docker exec -it unstract-backend python manage.py migrate
   ```

## 📦 Service Architecture

| Service | Port | Purpose |
|---------|------|---------|
| Frontend | 3000 | React UI |
| Backend | 8000 | Django API |
| PostgreSQL | 5432 | Primary database |
| Redis | 6379 | Cache & sessions |
| RabbitMQ | 5672/15672 | Message queue |
| MinIO | 9000/9001 | Object storage |
| Qdrant | 6333 | Vector database |
| Platform Service | 3001 | SDK communication |
| Prompt Service | 3003 | Prompt management |
| X2Text Service | 3004 | Text extraction |
| Runner | 5002 | Workflow execution |

## 🔧 Common Operations

### Stop All Services
```bash
docker compose -f docker/docker-compose.yaml down
```

### Restart a Service
```bash
docker compose -f docker/docker-compose.yaml restart [service-name]
```

### View Logs
```bash
# All services
docker compose -f docker/docker-compose.yaml logs -f

# Specific service
docker compose -f docker/docker-compose.yaml logs -f backend
```

### Update Configuration
1. Edit the appropriate `.env` file
2. Restart the affected service:
   ```bash
   docker compose -f docker/docker-compose.yaml restart [service-name]
   ```

### Reset Everything
```bash
# Stop and remove all containers and volumes
docker compose -f docker/docker-compose.yaml down -v

# Remove all env files
find . -name ".env" -type f -delete

# Start fresh
./setup-complete-env.sh && ./run-platform.sh
```

## 🔐 Security Notes

1. **Change default credentials** immediately after first login
2. **Backup encryption key** from backend/.env or platform-service/.env
3. **Use HTTPS** in production (see docker-compose-production.yaml)
4. **Update passwords** in essentials.env for databases

## 📞 Getting Help

- Check logs first: `docker compose logs -f`
- GitHub Issues: https://github.com/Zipstack/unstract/issues
- Slack Community: https://join-slack.unstract.com

## ✅ Next Steps

1. Log in with default credentials
2. Change admin password
3. Create your first workflow
4. Follow the Quick Start Guide in the main README