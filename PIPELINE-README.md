# GitLab CI/CD Pipeline for Employee Management System

## Pipeline Overview

This repository uses GitLab CI/CD for automated building, testing, and deployment of the Employee Management Spring Boot application.

### Pipeline Stages

1. **Validate** - Validates Maven POM and project structure
2. **Build** - Compiles and packages the application
3. **Test** - Runs unit tests and generates coverage reports
4. **Quality** - Code quality analysis (optional)
5. **Docker** - Builds and pushes container images
6. **Deploy** - Deploys to various environments

### Branch Strategy

- `main` → Production deployments
- `develop` → Development deployments
- `feature/*` → Build and test only
- `hotfix/*` → Hotfix testing

### Environment URLs

- **Development**: https://dev-employee-mgmt.yourdomain.com
- **Staging**: https://staging-employee-mgmt.yourdomain.com
- **Production**: https://employee-mgmt.yourdomain.com

### Container Registry

Images are stored in GitLab Container Registry:
```
registry.gitlab.com/[your-username]/devops-ems-spring-boot--docker--jenkins
```

### Manual Deployment

Deployments to staging and production require manual approval in the GitLab UI:

1. Go to **CI/CD > Pipelines**
2. Click on the pipeline for your branch
3. Click the "Play" button for the desired deployment stage

### Local Development

Use Docker Compose for local development:

```bash
# Build and run the application
docker-compose up --build

# Run with PostgreSQL database
docker-compose --profile with-db up --build

# Access the application
curl http://localhost:8080/api/employees
```

### Pipeline Variables

The following variables are configured in GitLab:

- `CI_REGISTRY` - GitLab Container Registry URL
- `CI_REGISTRY_USER` - Registry username (gitlab-ci-token)
- `CI_REGISTRY_PASSWORD` - Registry password (CI_JOB_TOKEN)

### Monitoring

- **Coverage Reports**: Available in pipeline artifacts
- **Test Reports**: Integrated with GitLab's test reporting
- **Container Scanning**: Security scanning of Docker images

For detailed setup instructions, see `GITLAB-PIPELINE-SETUP.md`.