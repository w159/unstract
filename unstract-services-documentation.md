# Unstract Services Documentation

## Default Login Credentials

### Main Application Login
- **URL**: http://localhost:3000 or http://frontend.unstract.localhost
- **Username**: `unstract`
- **Password**: `unstract`

### System Admin (Backend)
- **Username**: `admin`
- **Password**: `admin`
- **Email**: `admin@abc.com`

## How to Add New Users

### Method 1: Through the Web Interface
1. Login to Unstract with the default credentials above
2. Navigate to Settings/Users section
3. Create new users through the UI

### Method 2: Using Django Admin
1. Access Django admin (if enabled):
   ```bash
   docker exec -it unstract-backend python manage.py createsuperuser
   ```

### Method 3: Direct API Call
```bash
# Create user via API
curl -X POST http://localhost:8000/api/v1/users/register \
  -H "Content-Type: application/json" \
  -d '{
    "username": "newuser",
    "password": "password123",
    "email": "newuser@example.com"
  }'
```

## All Services and Access Points

### 1. Frontend (React App)
- **URLs**: 
  - http://localhost:3000
  - http://frontend.unstract.localhost
- **Purpose**: Main web interface for Unstract
- **Credentials**: Use default login above

### 2. Backend API
- **URL**: http://localhost:8000
- **API Docs**: http://localhost:8000/api/v1/docs
- **Purpose**: REST API backend
- **Default Credentials**: 
  - Username: `unstract`
  - Password: `unstract`

### 3. MinIO (Object Storage)
- **Console**: http://localhost:9001
- **API**: http://localhost:9000
- **Credentials**:
  - Username: `minio`
  - Password: `minio123`
- **Purpose**: S3-compatible object storage for documents
- **Setup**: Buckets are auto-created. Can create additional buckets via console.

### 4. PostgreSQL Database
- **Port**: 5432
- **Database**: `unstract_db`
- **Credentials**:
  - User: `unstract_dev`
  - Password: `unstract_pass`
- **Connection**: 
  ```bash
  psql -h localhost -p 5432 -U unstract_dev -d unstract_db
  ```

### 5. RabbitMQ (Message Queue)
- **Management UI**: http://localhost:15672
- **AMQP Port**: 5672
- **Credentials**:
  - Username: `admin`
  - Password: `admin`
- **Purpose**: Message broker for async tasks

### 6. Redis (Cache/Session Store)
- **Port**: 6379
- **No authentication by default**
- **Connection**:
  ```bash
  redis-cli -h localhost -p 6379
  ```

### 7. Qdrant (Vector Database)
- **Dashboard**: http://localhost:6333/dashboard
- **API**: http://localhost:6333
- **Purpose**: Vector storage for semantic search
- **No authentication by default**

### 8. Traefik (Reverse Proxy)
- **Dashboard**: http://localhost:8080
- **Purpose**: Routes requests to services
- **No authentication**

### 9. Flipt (Feature Flags)
- **UI**: http://localhost:8082
- **gRPC**: localhost:9005
- **Purpose**: Feature flag management
- **No authentication by default**

### 10. Platform Service
- **API**: http://localhost:3001
- **Purpose**: Platform management APIs

### 11. Prompt Service
- **API**: http://localhost:3003
- **Purpose**: Prompt engineering service

### 12. X2Text Service
- **API**: http://localhost:3004
- **Purpose**: Document text extraction

### 13. Runner Service
- **API**: http://localhost:5002
- **Purpose**: Workflow execution

## Worker Services (No Web Interface)
These run in the background:
- `unstract-worker`: General task worker
- `unstract-worker-file-processing`: File processing tasks
- `unstract-worker-file-processing-callback`: Callback handler
- `unstract-worker-logging`: Log processing
- `unstract-celery-beat`: Scheduled tasks

## Setup and Improvements

### 1. Security Improvements
```bash
# Change default passwords in .env files before deployment:
# - backend/.env
# - docker/essentials.env
```

### 2. Enable HTTPS
- Configure Traefik with SSL certificates
- Update docker-compose.yaml with SSL configuration

### 3. Database Backups
```bash
# Backup PostgreSQL
docker exec unstract-db pg_dump -U unstract_dev unstract_db > backup.sql

# Restore
docker exec -i unstract-db psql -U unstract_dev unstract_db < backup.sql
```

### 4. MinIO Backups
```bash
# Sync MinIO data
docker run --rm -v unstract_minio_data:/data alpine tar -czf - -C /data . > minio-backup.tar.gz
```

### 5. Monitoring Setup
- Prometheus endpoint available at each service's `/metrics` endpoint
- Can integrate with Grafana for visualization

### 6. Scaling Options
- Use Docker Swarm or Kubernetes for production
- Scale workers based on load:
  ```bash
  docker-compose up -d --scale worker=3
  ```

## Azure Container Registry Info
Your ACR details from the JSON file:
- **Registry**: acrunstract21468.azurecr.io
- **Location**: East US
- **Admin Enabled**: Yes
- **Created By**: da-jmorgan@Henssler.com

To push images to ACR:
```bash
az acr login --name acrunstract21468
docker tag unstract/backend:latest acrunstract21468.azurecr.io/unstract/backend:latest
docker push acrunstract21468.azurecr.io/unstract/backend:latest
```