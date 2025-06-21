# Unstract Local Development Access Guide

## MinIO Console
- **URL**: http://localhost:9001
- **Username**: `minio`
- **Password**: `minio123`

## Direct Service Access (Working)
Since Traefik routing has issues, use these direct ports:

### Frontend
- **URL**: http://localhost:3000
- **Note**: This is the React frontend application

### Backend API
- **URL**: http://localhost:8000
- **API Docs**: http://localhost:8000/api/v1/docs
- **Health Check**: http://localhost:8000/api/v1/health

### Other Services
- **RabbitMQ Management**: http://localhost:15672
  - Username: `guest`
  - Password: `guest`
  
- **PostgreSQL Database**: localhost:5432
  - Database: `unstract_db`
  - Username: `unstract_dev`
  - Password: `unstract_pass`

- **Redis**: localhost:6379

## Quick Fix Options

### Option 1: Use Simple Setup (Recommended)
```bash
./simple-local-setup.sh
```
This bypasses Traefik and uses direct port access.

### Option 2: Fix Traefik Routing
```bash
./fix-traefik-routing.sh
```
This attempts to fix the Traefik configuration.

### Option 3: Direct Docker Commands
```bash
# Access frontend directly
open http://localhost:3000

# Access backend API
open http://localhost:8000

# Access MinIO console
open http://localhost:9001
```

## Troubleshooting

### Check Service Status
```bash
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
```

### View Logs
```bash
# Frontend logs
docker logs unstract-frontend

# Backend logs
docker logs unstract-backend

# Traefik logs
docker logs unstract-proxy
```

### Test API
```bash
# Health check
curl http://localhost:8000/api/v1/health

# Login page
curl http://localhost:8000/api/v1/login
```