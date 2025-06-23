# Builder stage
FROM node:20-alpine AS builder

# Set build-time environment variables
ENV BUILD_CONTEXT_PATH=frontend
ENV NODE_ENV=production
ENV NODE_OPTIONS=--max-old-space-size=4096

# Set the working directory
WORKDIR /app

# Copy dependency files
COPY ${BUILD_CONTEXT_PATH}/package.json ${BUILD_CONTEXT_PATH}/package-lock.json ./

# Install dependencies with clean cache
RUN npm ci --prefer-offline --no-audit --progress=false && \
    npm cache clean --force

# Copy application source
COPY ${BUILD_CONTEXT_PATH}/ .

# Build the application
RUN npm run build

# Production stage
FROM nginx:1.25-alpine

LABEL maintainer="Zipstack Inc."

# Copy built assets from builder
COPY --from=builder /app/build /usr/share/nginx/html

# Copy custom NGINX configuration
COPY --from=builder /app/nginx.conf /etc/nginx/nginx.conf

# Set up runtime directory and permissions
RUN mkdir -p /usr/share/nginx/html/config && \
    chown -R nginx:nginx /usr/share/nginx/html && \
    chmod -R 755 /usr/share/nginx/html && \
    chmod +x /docker-entrypoint.d/*.sh 2>/dev/null || true

# Copy environment configuration script
COPY --chmod=755 ${BUILD_CONTEXT_PATH:-frontend}/generate-runtime-config.sh /docker-entrypoint.d/40-env.sh

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:80/ || exit 1

# Expose port 80
EXPOSE 80

# Run as non-root user
USER nginx

# Start NGINX
CMD ["nginx", "-g", "daemon off;"]
