#!/usr/bin/env bash

# Unstract Quick Start Script
# This script sets up and runs Unstract with a single command

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}"
echo "╔══════════════════════════════════════════╗"
echo "║        UNSTRACT QUICK START              ║"
echo "║   No-code LLM Platform for Documents     ║"
echo "╚══════════════════════════════════════════╝"
echo -e "${NC}"

echo -e "${YELLOW}Starting Unstract setup...${NC}"
echo ""

# Check prerequisites
echo "📋 Checking prerequisites..."

# Check Docker
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker is not installed${NC}"
    echo "Please install Docker from https://docs.docker.com/get-docker/"
    exit 1
fi

if ! docker info &> /dev/null; then
    echo -e "${RED}❌ Docker daemon is not running${NC}"
    echo "Please start Docker and try again"
    exit 1
fi

# Check Python
if ! command -v python3 &> /dev/null; then
    echo -e "${RED}❌ Python3 is not installed${NC}"
    echo "Please install Python 3.x"
    exit 1
fi

echo -e "${GREEN}✅ All prerequisites met${NC}"
echo ""

# Run environment setup if needed
if [ ! -f "backend/.env" ] || [ ! -f "docker/.env" ]; then
    echo "🔧 Setting up environment files..."
    ./setup-complete-env.sh
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}❌ Environment setup failed${NC}"
        exit 1
    fi
    echo -e "${GREEN}✅ Environment setup complete${NC}"
else
    echo -e "${GREEN}✅ Environment files already exist${NC}"
fi

echo ""

# Run verification
echo "🔍 Verifying setup..."
./verify-setup.sh

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Setup verification failed${NC}"
    echo "Please fix the issues above and try again"
    exit 1
fi

echo ""

# Start the platform
echo -e "${BLUE}🚀 Starting Unstract platform...${NC}"
./run-platform.sh

echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                  UNSTRACT IS STARTING!                   ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""
echo "⏱️  Services are starting up (this may take 30-60 seconds)..."
echo ""
echo "📍 Once ready, access Unstract at:"
echo -e "   ${BLUE}http://frontend.unstract.localhost${NC}"
echo ""
echo "🔑 Default credentials:"
echo "   Username: unstract"
echo "   Password: unstract"
echo ""
echo "📚 Resources:"
echo "   - Docker Setup Guide: DOCKER-SETUP-GUIDE.md"
echo "   - Troubleshooting: DOCKER-SETUP-GUIDE.md#troubleshooting"
echo "   - Main Documentation: README.md"
echo ""
echo -e "${YELLOW}💡 Tip: Run 'docker compose -f docker/docker-compose.yaml logs -f' to view logs${NC}"