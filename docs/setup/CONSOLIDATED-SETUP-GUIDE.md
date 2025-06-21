# Unstract Platform - Consolidated Setup Guide

## Quick Start

```bash
# 1. Run the setup script
./scripts/setup/setup-environment.sh

# 2. Deploy locally
./scripts/deploy/deploy-unstract.sh

# 3. Deploy to production
./scripts/deploy/deploy-unstract.sh --production
```

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Environment Setup](#environment-setup)
3. [Deployment Options](#deployment-options)
4. [Troubleshooting](#troubleshooting)
5. [Architecture Overview](#architecture-overview)

## Prerequisites

- Docker Desktop (latest version)
- Docker Compose v2.0+
- Python 3.8+ (for key generation)
- 8GB RAM minimum (16GB recommended)
- 20GB free disk space

### macOS Specific
- Docker Desktop for Mac
- Enable "Use new virtualization framework" in Docker settings

## Environment Setup

### Automatic Setup
```bash
./scripts/setup/setup-environment.sh
```

This script will:
- Create all necessary `.env` files from samples
- Generate secure API keys and encryption keys
- Fix Docker networking issues
- Create required directories
- Handle macOS-specific DNS issues

### Manual Setup

1. **Copy environment files:**
   ```bash
   cp backend/sample.env backend/.env
   cp frontend/sample.env frontend/.env
   ```

2. **Generate secure keys:**
   ```python
   # Python script to generate keys
   import secrets
   from cryptography.fernet import Fernet
   
   # API Keys
   api_key = secrets.token_urlsafe(32)
   
   # Encryption Key
   encryption_key = Fernet.generate_key().decode()
   ```

3. **Update `.env` files with generated keys**

## Deployment Options

### Local Development
```bash
./scripts/deploy/deploy-unstract.sh
```

- Uses `docker-compose.yaml`
- Includes hot-reload for development
- Creates default admin user (admin/admin)

### Production Deployment
```bash
./scripts/deploy/deploy-unstract.sh --production
```

- Uses `docker-compose-production.yaml`
- Includes Traefik reverse proxy
- SSL/TLS ready
- Production-optimized settings

### Azure Container Registry
```bash
./scripts/deploy/deploy-unstract.sh --acr
```

- Pulls images from ACR
- Requires Azure authentication

### macOS M1/M2
```bash
./scripts/deploy/deploy-unstract.sh --mac
```

- Sets correct platform for ARM processors
- Handles Docker Desktop compatibility

## Service Architecture

### Core Services
- **Frontend**: React application (port 3000)
- **Backend**: Django REST API (port 8000)
- **PostgreSQL**: Primary database
- **Redis**: Caching and sessions
- **RabbitMQ**: Message queue for Celery

### Processing Services
- **Celery Workers**: Async task processing
- **Platform Service**: Core platform APIs
- **Prompt Service**: Prompt management
- **X2Text Service**: Document extraction
- **Runner Service**: Workflow execution

### Infrastructure Services
- **Traefik**: Reverse proxy (production)
- **Nginx**: Static file serving
- **MinIO**: Object storage
- **Qdrant**: Vector database

## Troubleshooting

### Common Issues

#### Docker DNS Issues (macOS)
```bash
# The setup script handles this automatically, but manually:
docker run --rm busybox nslookup google.com
# If fails, restart Docker Desktop
```

#### Port Conflicts
```bash
# Check what's using ports
lsof -i :3000  # Frontend
lsof -i :8000  # Backend
lsof -i :5432  # PostgreSQL
```

#### Service Health Checks
```bash
# Check all services
docker compose -f docker/docker-compose.yaml ps

# View logs
docker compose -f docker/docker-compose.yaml logs -f [service-name]

# Restart specific service
docker compose -f docker/docker-compose.yaml restart [service-name]
```

#### Database Issues
```bash
# Reset database (WARNING: destroys data)
docker compose -f docker/docker-compose.yaml down -v
docker compose -f docker/docker-compose.yaml up -d
```

### Performance Optimization

#### Docker Desktop Settings (macOS)
- CPUs: 4+ cores
- Memory: 8GB+
- Swap: 2GB+
- Disk image size: 64GB+

#### Production Tuning
Edit `backend/.env.production`:
```env
GUNICORN_WORKERS=4
GUNICORN_THREADS=2
CONN_MAX_AGE=600
```

## Security Considerations

### Required Environment Variables
- `DJANGO_SECRET_KEY`: Django secret key
- `ENCRYPTION_KEY`: For credential encryption
- `*_API_KEY`: Various service API keys

### Production Checklist
- [ ] Change all default passwords
- [ ] Generate new secret keys
- [ ] Configure SSL certificates
- [ ] Set proper CORS origins
- [ ] Enable firewall rules
- [ ] Configure backup strategy

## Monitoring

### Health Endpoints
- Frontend: http://localhost:3000/health
- Backend: http://localhost:8000/api/v1/health
- Platform Service: http://localhost:3001/health

### Logs Location
- Container logs: `docker compose logs`
- Application logs: `/data/logs/` (inside containers)

## Backup and Recovery

### Database Backup
```bash
# Backup
docker compose exec unstract-db pg_dump -U unstract_dev unstract_db > backup.sql

# Restore
docker compose exec -T unstract-db psql -U unstract_dev unstract_db < backup.sql
```

### File Storage Backup
```bash
# Backup MinIO data
tar -czf minio-backup.tar.gz ./data/minio
```

## Updates and Maintenance

### Updating Images
```bash
# Pull latest images
docker compose -f docker/docker-compose.yaml pull

# Restart with new images
docker compose -f docker/docker-compose.yaml up -d
```

### Database Migrations
```bash
docker compose exec backend python manage.py migrate
```

## Additional Resources

- [Docker Dependencies](../DOCKER-DEPENDENCIES.md)
- [SonarCloud Issues](../../archive/reports/ISSUES_ROADMAP.md)
- [API Documentation](http://localhost:8000/api/docs)