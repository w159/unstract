# Docker Container Dependencies Analysis

## Service Dependency Graph

```
┌─────────────────────────────────────────────────────────────────────┐
│                           Traefik (Reverse Proxy)                    │
│                                    │                                 │
│                    ┌───────────────┴───────────────┐                │
│                    ▼                               ▼                │
│               Frontend (3000)                Backend (8000)          │
│                                                    │                 │
│                              ┌─────────────────────┼─────────┐      │
│                              │                     │         │      │
│                              ▼                     ▼         ▼      │
│                     Platform Service (3001)   Workers    Celery Beat │
│                     Prompt Service (3003)        │           │      │
│                     X2Text Service (3004)        │           │      │
│                     Runner (5002)                │           │      │
│                              │                    │           │      │
│        ┌─────────────────────┼────────────────────┼───────────┘      │
│        ▼                     ▼                    ▼                  │
│   PostgreSQL (5432)    RabbitMQ (5672)      Redis (6379)           │
│        │                                          │                  │
│        ▼                                          ▼                  │
│   Qdrant (6333)                            MinIO (9000)             │
└─────────────────────────────────────────────────────────────────────┘
```

## Critical Dependencies

### 1. Database Layer

- **PostgreSQL**: Primary data store for all services
  - Used by: Backend, Platform Service, Prompt Service, X2Text Service, Workers
  - Health check: `pg_isready`
  - Critical for: Application data, user management, workflows

### 2. Message Queue

- **RabbitMQ**: Async task processing
  - Used by: Backend, all Workers, Celery Beat
  - Health check: Management API at :15672
  - Critical for: Background jobs, file processing

### 3. Cache Layer

- **Redis**: Session storage and caching
  - Used by: Backend, Platform Service, Runner
  - Health check: `redis-cli ping`
  - Critical for: User sessions, API caching

### 4. Object Storage

- **MinIO**: File storage (S3-compatible)
  - Used by: Backend, Prompt Service
  - Dependency: `createbuckets` container for initialization
  - Critical for: Document storage, prompt data

### 5. Vector Database

- **Qdrant**: Vector similarity search
  - Used by: Backend (via prompt studio)
  - Health check: HTTP API at :6333
  - Critical for: Document embeddings

## Service Start Order

1. **Essential Services** (must start first):
   - PostgreSQL (db)
   - Redis
   - RabbitMQ
   - MinIO
   - Qdrant
   - Traefik (reverse-proxy)

2. **Initialization Services**:
   - createbuckets (MinIO bucket creation)

3. **Core Services** (depend on essentials):
   - Platform Service
   - Prompt Service
   - X2Text Service
   - Runner

4. **Application Layer**:
   - Backend (depends on all core services)
   - Workers (depend on Backend)
   - Celery Beat

5. **Frontend**:
   - Frontend (depends on Backend)

## Health Checks & Readiness

### PostgreSQL

```yaml
healthcheck:
  test: ["CMD-SHELL", "pg_isready -U $${POSTGRES_USER} -d $${POSTGRES_DB}"]
  interval: 10s
  timeout: 5s
  retries: 5
```

### Redis

```yaml
healthcheck:
  test: ["CMD", "redis-cli", "ping"]
  interval: 10s
  timeout: 5s
  retries: 5
```

### RabbitMQ

```yaml
healthcheck:
  test: ["CMD", "rabbitmq-diagnostics", "ping"]
  interval: 10s
  timeout: 5s
  retries: 5
```

### Backend Services

```yaml
healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost:PORT/health"]
  interval: 30s
  timeout: 10s
  retries: 3
  start_period: 40s
```

## Environment Variable Dependencies

### Shared Across Services

- `POSTGRES_*`: Database credentials
- `REDIS_*`: Cache configuration
- `RABBITMQ_*`: Message queue settings
- `MINIO_*`: Object storage credentials
- `ENCRYPTION_KEY`: Must be identical across Backend and Platform Service

### Service-Specific

- Backend: Requires all service endpoints
- Workers: Inherit Backend configuration
- Frontend: Only needs Backend URL

## Volume Dependencies

### Shared Volumes

- `prompt_studio_data`: Shared between Backend and createbuckets
- `workflow_data`: Shared between Backend and Workers
- `postgres_data`: PostgreSQL persistence
- `redis_data`: Redis persistence
- `minio_data`: MinIO persistence
- `qdrant_data`: Qdrant persistence
- `rabbitmq_data`: RabbitMQ persistence

### Docker Socket

- Runner service requires `/var/run/docker.sock` for spawning tool containers

## Network Configuration

### Internal Network

- Network name: `unstract-network`
- All services communicate on this network
- Traefik routes external traffic

### Service Discovery

- Services reference each other by container name
- Example: `http://unstract-backend:8000`

### External Access

- Frontend: <http://frontend.unstract.localhost>
- Backend API: <http://frontend.unstract.localhost/api/v1>
- Traefik Dashboard: <http://localhost:8080>
- MinIO Console: <http://localhost:9001>
- RabbitMQ Management: <http://localhost:15672>
- Qdrant Dashboard: <http://localhost:6333/dashboard>

## Common Issues & Solutions

### 1. Service Start Failures

- **Cause**: Dependencies not ready
- **Solution**: Implement proper health checks and restart policies

### 2. Network Connectivity

- **Cause**: Services on different networks
- **Solution**: Ensure all services use `unstract-network`

### 3. Volume Permissions

- **Cause**: Container user mismatch
- **Solution**: Set proper user/group in Dockerfile

### 4. Resource Constraints

- **Cause**: Insufficient memory/CPU
- **Solution**: Set resource limits in docker-compose

## Monitoring & Debugging

### Check Service Status

```bash
docker compose -f docker/docker-compose.yaml ps
```

### View Service Logs

```bash
docker compose -f docker/docker-compose.yaml logs -f [service-name]
```

### Inspect Network

```bash
docker network inspect unstract-network
```

### Check Volume Usage

```bash
docker volume ls
docker volume inspect [volume-name]
```
