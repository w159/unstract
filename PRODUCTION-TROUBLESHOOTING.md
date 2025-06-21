# Unstract Production Troubleshooting Guide

## Common Issues and Solutions

### 1. Frontend Stuck on "Configuring your..." Loading Screen

**Symptoms:**
- Page loads but shows endless loading spinner
- Message says "Configuring your something or other"
- Have to clear browser storage/cookies to access site

**Root Causes:**
- Session cookie misconfiguration
- Backend API not accessible from frontend
- CORS issues
- Redis session storage problems

**Solutions:**
```bash
# Check session configuration
docker-compose exec backend python manage.py shell
>>> from django.conf import settings
>>> print(settings.SESSION_ENGINE)  # Should be 'django.contrib.sessions.backends.cache'
>>> print(settings.SESSION_COOKIE_SECURE)  # Should match your HTTPS setup

# Clear all Redis sessions
docker-compose exec redis redis-cli FLUSHDB

# Check backend health
curl -I http://localhost:8000/api/v1/health/

# Check CORS settings
grep CORS backend/.env
```

### 2. Document Upload Failures

**Symptoms:**
- Upload starts but fails
- Network errors in browser console
- 413 Request Entity Too Large
- 504 Gateway Timeout

**Solutions:**
```bash
# Increase nginx client_max_body_size
# Already set to 100M in nginx-frontend-production.conf

# Check MinIO connectivity
docker-compose exec backend python manage.py shell
>>> from minio import Minio
>>> client = Minio('unstract-minio:9000', access_key='minio', secret_key='minio123')
>>> client.bucket_exists('unstract')

# Monitor Celery workers
docker-compose logs -f worker-file-processing

# Check RabbitMQ queues
docker-compose exec rabbitmq rabbitmqctl list_queues
```

### 3. Missing Frontend Components

**Symptoms:**
- Can't add/edit users
- Missing UI elements
- Features not loading

**Root Causes:**
- Feature flags misconfigured
- API endpoints returning 404
- React build issues

**Solutions:**
```bash
# Check feature flags
curl http://localhost:8082/api/v1/flags

# Verify API endpoints
curl -H "Authorization: Bearer YOUR_TOKEN" http://localhost:8000/api/v1/users/

# Rebuild frontend with correct env
cd frontend
npm run build
docker build -t unstract/frontend:latest .
```

### 4. Worker/Celery Issues

**Symptoms:**
- Tasks stuck in pending
- Async operations not completing
- Background jobs failing

**Solutions:**
```bash
# Check Celery worker status
docker-compose exec worker celery -A backend inspect active

# Monitor Celery flower (if enabled)
docker-compose --profile optional up -d celery-flower
# Visit http://localhost:5555

# Check RabbitMQ management
# Visit http://localhost:15672 (admin/password)

# Restart workers
docker-compose restart worker worker-logging worker-file-processing
```

### 5. Traefik Routing Issues

**Symptoms:**
- Can only access via DNS, not port
- API calls failing with 404
- WebSocket connections dropping

**Solutions:**
```bash
# Check Traefik routing
curl http://localhost:8080/api/rawdata

# Test backend directly
docker-compose exec backend curl http://localhost:8000/api/v1/health/

# Check Traefik logs
docker-compose logs -f reverse-proxy

# Validate labels
docker-compose config | grep -A5 "traefik"
```

### 6. Database Connection Issues

**Symptoms:**
- OperationalError: could not connect to server
- Database migrations failing
- Slow queries

**Solutions:**
```bash
# Check database connectivity
docker-compose exec backend python manage.py dbshell

# Run migrations manually
docker-compose exec backend python manage.py migrate --noinput

# Check connection pool
docker-compose exec db psql -U unstract_dev -d unstract_db -c "SELECT count(*) FROM pg_stat_activity;"

# Vacuum database
docker-compose exec db psql -U unstract_dev -d unstract_db -c "VACUUM ANALYZE;"
```

## Production Checklist

### Before Going Live:

1. **Security**
   - [ ] Change all default passwords
   - [ ] Generate new secret keys
   - [ ] Enable HTTPS with valid certificates
   - [ ] Configure firewall rules
   - [ ] Set up backup strategy

2. **Performance**
   - [ ] Configure Redis maxmemory policy
   - [ ] Set appropriate worker autoscaling
   - [ ] Enable PostgreSQL connection pooling
   - [ ] Configure nginx caching

3. **Monitoring**
   - [ ] Set up log aggregation
   - [ ] Configure health checks
   - [ ] Set up alerts for critical services
   - [ ] Monitor disk space

4. **Configuration**
   - [ ] Update all `.env` files
   - [ ] Set production domains
   - [ ] Configure email settings
   - [ ] Set up OAuth if needed

## Monitoring Commands

```bash
# Check all service status
docker-compose ps

# Monitor resource usage
docker stats

# Check logs for errors
docker-compose logs --tail=100 | grep -i error

# Database connections
docker-compose exec db psql -U unstract_dev -c "SELECT count(*) FROM pg_stat_activity;"

# Redis memory usage
docker-compose exec redis redis-cli INFO memory

# Celery queue sizes
docker-compose exec rabbitmq rabbitmqctl list_queues
```

## Emergency Procedures

### Complete Reset
```bash
# Stop all services
docker-compose down

# Clear all data (WARNING: This deletes everything!)
docker volume prune -f

# Restart fresh
docker-compose up -d
```

### Session Issues
```bash
# Clear all sessions
docker-compose exec redis redis-cli -n 2 FLUSHDB

# Restart backend
docker-compose restart backend
```

### Worker Issues
```bash
# Purge all queues
docker-compose exec rabbitmq rabbitmqctl purge_queue celery
docker-compose exec rabbitmq rabbitmqctl purge_queue file_processing

# Restart all workers
docker-compose restart worker worker-logging worker-file-processing
```

## Contact Support

If issues persist:
1. Check logs: `docker-compose logs [service-name]`
2. Review configuration in `.env` files
3. Verify network connectivity between services
4. Check disk space and system resources