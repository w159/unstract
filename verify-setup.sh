#!/usr/bin/env bash

# Script to verify Unstract setup is complete

echo "🔍 Verifying Unstract Setup..."
echo "================================"

# Check environment files
echo "📁 Checking environment files..."
missing_env=0

check_env_file() {
    if [ -f "$1" ]; then
        echo "✅ $1 exists"
    else
        echo "❌ $1 missing"
        missing_env=$((missing_env + 1))
    fi
}

check_env_file "backend/.env"
check_env_file "platform-service/.env"
check_env_file "prompt-service/.env"
check_env_file "x2text-service/.env"
check_env_file "runner/.env"
check_env_file "docker/essentials.env"
check_env_file "docker/.env"

if [ $missing_env -gt 0 ]; then
    echo ""
    echo "⚠️  Missing $missing_env environment files!"
    echo "Run: ./setup-complete-env.sh"
    exit 1
fi

# Check Docker
echo ""
echo "🐳 Checking Docker..."
if command -v docker &> /dev/null; then
    echo "✅ Docker installed"
    if docker info &> /dev/null; then
        echo "✅ Docker daemon running"
    else
        echo "❌ Docker daemon not running"
        echo "Start Docker and try again"
        exit 1
    fi
else
    echo "❌ Docker not installed"
    exit 1
fi

# Check Docker Compose
if docker compose version &> /dev/null; then
    echo "✅ Docker Compose installed"
elif command -v docker-compose &> /dev/null; then
    echo "✅ Docker Compose (standalone) installed"
else
    echo "❌ Docker Compose not installed"
    exit 1
fi

# Check Python
echo ""
echo "🐍 Checking Python..."
if command -v python3 &> /dev/null; then
    echo "✅ Python3 installed"
else
    echo "❌ Python3 not installed"
    exit 1
fi

# Check encryption key
echo ""
echo "🔐 Checking encryption key..."
if [ -f "backend/.env" ]; then
    if grep -q "ENCRYPTION_KEY=\"Sample-Key\"" backend/.env; then
        echo "⚠️  Using sample encryption key - NOT SECURE!"
        echo "Run: ./setup-complete-env.sh to generate a secure key"
    else
        echo "✅ Custom encryption key set"
    fi
fi

# Check credentials
echo ""
echo "🔑 Checking default credentials..."
if [ -f "backend/.env" ]; then
    if grep -q "DEFAULT_AUTH_USERNAME=\"unstract\"" backend/.env && \
       grep -q "DEFAULT_AUTH_PASSWORD=\"unstract\"" backend/.env; then
        echo "✅ Default credentials configured"
        echo "   Username: unstract"
        echo "   Password: unstract"
    else
        echo "⚠️  Default credentials not properly set"
    fi
fi

# Check port availability
echo ""
echo "🌐 Checking port availability..."
check_port() {
    if lsof -Pi :$1 -sTCP:LISTEN -t >/dev/null 2>&1; then
        echo "❌ Port $1 ($2) is already in use"
        return 1
    else
        echo "✅ Port $1 ($2) is available"
        return 0
    fi
}

ports_available=0
check_port 3000 "Frontend" || ports_available=$((ports_available + 1))
check_port 8000 "Backend API" || ports_available=$((ports_available + 1))
check_port 5432 "PostgreSQL" || ports_available=$((ports_available + 1))
check_port 6379 "Redis" || ports_available=$((ports_available + 1))
check_port 9000 "MinIO" || ports_available=$((ports_available + 1))
check_port 5672 "RabbitMQ" || ports_available=$((ports_available + 1))

if [ $ports_available -gt 0 ]; then
    echo ""
    echo "⚠️  $ports_available ports are already in use!"
    echo "Stop conflicting services or change ports in docker-compose.yaml"
fi

# Final summary
echo ""
echo "================================"
if [ $missing_env -eq 0 ] && [ $ports_available -eq 0 ]; then
    echo "✅ Setup verification complete!"
    echo ""
    echo "🚀 Ready to run: ./run-platform.sh"
    echo ""
    echo "📝 Once running, access at:"
    echo "   http://frontend.unstract.localhost"
    echo "   Username: unstract"
    echo "   Password: unstract"
else
    echo "❌ Setup incomplete. Fix the issues above and run this script again."
    exit 1
fi