# Unstract Platform

An open-source platform for document processing and workflow automation using LLMs.

## 🚀 Quick Start

```bash
# Setup environment
./scripts/setup/setup-environment.sh

# Deploy locally
./scripts/deploy/deploy-unstract.sh

# Access the platform
# Frontend: http://localhost:3000
# API: http://localhost:8000/api/v1
```

## 📚 Documentation

- **[Setup Guide](docs/setup/CONSOLIDATED-SETUP-GUIDE.md)** - Complete setup and deployment instructions
- **[Docker Dependencies](DOCKER-DEPENDENCIES.md)** - Service dependency graph
- **[Issues Roadmap](ISSUES_ROADMAP.md)** - Current development status and fixes

## 🏗️ Project Structure

```
unstract/
├── backend/            # Django REST API
├── frontend/           # React application
├── platform-service/   # Core platform service
├── prompt-service/     # Prompt management
├── runner/            # Workflow execution
├── x2text-service/    # Document extraction
├── docker/            # Docker configurations
├── scripts/           # Automation scripts
│   ├── setup/        # Environment setup
│   └── deploy/       # Deployment scripts
├── docs/             # Documentation
└── archive/          # Historical files
```

## 🛠️ Key Features

- **Document Processing**: Extract structured data from unstructured documents
- **Workflow Automation**: Build and deploy document processing pipelines
- **LLM Integration**: Support for multiple LLM providers (OpenAI, Anthropic, etc.)
- **Prompt Studio**: Interactive prompt engineering environment
- **API Deployments**: Deploy workflows as REST APIs
- **Multi-tenant**: Organization and user management

## 🐳 Services Overview

| Service | Port | Description |
|---------|------|-------------|
| Frontend | 3000 | React web application |
| Backend | 8000 | Django REST API |
| PostgreSQL | 5432 | Primary database |
| Redis | 6379 | Caching and sessions |
| RabbitMQ | 5672 | Message queue |
| MinIO | 9000 | Object storage |

## 🔧 Development

### Prerequisites
- Docker Desktop
- Docker Compose v2.0+
- Python 3.8+
- Node.js 16+ (for frontend development)

### Local Development
```bash
# Start all services
./scripts/deploy/deploy-unstract.sh

# View logs
docker compose -f docker/docker-compose.yaml logs -f

# Stop services
docker compose -f docker/docker-compose.yaml down
```

### Running Tests
```bash
# Backend tests
docker compose exec backend pytest

# Frontend tests
docker compose exec frontend npm test
```

## 🚢 Production Deployment

```bash
# Deploy with production settings
./scripts/deploy/deploy-unstract.sh --production
```

See [Setup Guide](docs/setup/CONSOLIDATED-SETUP-GUIDE.md) for detailed production configuration.

## 🤝 Contributing

Please read [CONTRIBUTING.md](CONTRIBUTING.md) for details on our code of conduct and the process for submitting pull requests.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🔗 Links

- [Official Documentation](https://docs.unstract.com)
- [GitHub Repository](https://github.com/Unstract-IO/unstract)
- [Discord Community](https://discord.gg/unstract)

## ⚠️ Important Notes

- Default credentials are for development only. Change them in production!
- The `archive/` directory contains historical files and is not tracked by git
- Run the setup script before first deployment to generate secure keys