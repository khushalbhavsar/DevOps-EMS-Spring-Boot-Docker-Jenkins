# GitLab CI/CD Pipeline Setup Guide

## 🚀 Complete Setup Instructions for Employee Management System

### 1. GitLab Project Settings Configuration

#### A. Enable GitLab Container Registry
1. Go to your GitLab project
2. Navigate to **Settings > General > Visibility, project features, permissions**
3. Enable **Container Registry**
4. Save changes

#### B. Configure CI/CD Variables
Navigate to **Settings > CI/CD > Variables** and add the following:

| Variable Name | Value | Type | Protected | Masked |
|---------------|--------|------|-----------|--------|
| `CI_REGISTRY` | `registry.gitlab.com` | Variable | No | No |
| `CI_REGISTRY_USER` | `gitlab-ci-token` | Variable | No | No |
| `CI_REGISTRY_PASSWORD` | `$CI_JOB_TOKEN` | Variable | No | Yes |
| `DOCKER_HOST` | `tcp://docker:2376` | Variable | No | No |

#### C. Enable Shared Runners
1. Go to **Settings > CI/CD > Runners**
2. Enable **Shared Runners** for your project
3. Verify runners are available and active

### 2. GitLab Runner Configuration (If Self-Hosted)

```bash
# Install GitLab Runner (Ubuntu/Debian)
curl -L "https://packages.gitlab.com/install/repositories/runner/gitlab-runner/script.deb.sh" | sudo bash
sudo apt-get install gitlab-runner

# Register Runner
sudo gitlab-runner register
# Follow prompts:
# - GitLab URL: https://gitlab.com/
# - Registration token: (from Settings > CI/CD > Runners)
# - Description: "Docker Runner"
# - Tags: "docker,maven,spring-boot"
# - Executor: "docker"
# - Default image: "maven:3.9.3-eclipse-temurin-17"
```

### 3. Pipeline Stages Explained

#### 🔍 **Validate Stage**
- **Purpose**: Early validation of POM structure and dependencies
- **Triggers**: MRs, main, develop branches
- **Duration**: ~30 seconds

#### 🏗️ **Build Stage**
- **Purpose**: Compile and package the Spring Boot application
- **Artifacts**: Creates JAR file stored for 1 hour
- **Reports**: JUnit test reports
- **Triggers**: MRs, main, develop branches

#### 🧪 **Test Stage**
- **Purpose**: Execute unit tests and generate coverage reports
- **Coverage**: Extracts coverage percentage from output
- **Artifacts**: Test reports, coverage data (30 days retention)
- **Triggers**: MRs, main, develop branches

#### 📊 **Quality Stage** 
- **Purpose**: Code quality analysis (optional)
- **Tools**: Checkstyle, can integrate SonarQube
- **Failure**: Allowed to fail (won't block pipeline)

#### 🐳 **Docker Stage**
- **Purpose**: Build and push container images
- **Images**: Creates both tagged and latest versions
- **Registry**: Uses GitLab Container Registry
- **Triggers**: main, develop branches only

#### 🚀 **Deploy Stages**
- **Development**: Auto-deploys develop branch (manual trigger)
- **Staging**: Auto-deploys main branch (manual trigger)  
- **Production**: Manual deployment from main branch

### 4. Environment URLs Configuration

Update the environment URLs in `.gitlab-ci.yml`:

```yaml
environment:
  name: production
  url: https://your-domain.com  # Replace with your actual domain
```

### 5. Branch Strategy

#### Recommended Git Flow:
- **`main`** → Production deployments
- **`develop`** → Development deployments  
- **`feature/*`** → Feature branches (build + test only)
- **`hotfix/*`** → Hotfix branches

### 6. Deployment Configuration

#### For Kubernetes Deployment:
```yaml
script:
  - kubectl set image deployment/employee-mgmt employee-mgmt=$CI_REGISTRY_IMAGE:$CI_COMMIT_SHORT_SHA
  - kubectl rollout status deployment/employee-mgmt
```

#### For Docker Compose Deployment:
```yaml
script:
  - docker-compose pull
  - docker-compose up -d
```

#### For AWS ECS Deployment:
```yaml
script:
  - aws ecs update-service --cluster production --service employee-mgmt --force-new-deployment
```

### 7. Monitoring and Notifications

#### Slack Integration:
1. Go to **Settings > Integrations**
2. Configure **Slack notifications**
3. Set channels for pipeline failures/successes

#### Email Notifications:
- Configure in **Settings > Notifications**
- Set notification levels for pipeline events

### 8. Pipeline Optimization Tips

#### Cache Configuration:
```yaml
cache:
  key: "$CI_JOB_NAME-$CI_COMMIT_REF_SLUG"
  paths:
    - .m2/repository/
  policy: pull-push
```

#### Parallel Jobs:
```yaml
test:parallel:
  parallel: 3
  script:
    - mvn test -Dtest.single="**/*Test$CI_NODE_INDEX.java"
```

### 9. Security Best Practices

1. **Use Protected Variables** for sensitive data
2. **Enable Branch Protection** for main/develop
3. **Require MR Approvals** before merging
4. **Scan Dependencies** for vulnerabilities
5. **Use Specific Image Tags** (avoid `:latest` in production)

### 10. Troubleshooting Common Issues

#### Docker Permission Issues:
```yaml
before_script:
  - docker info  # Verify Docker daemon is accessible
```

#### Maven Cache Issues:
```bash
# Clear cache if builds fail
rm -rf .m2/repository
```

#### Registry Login Issues:
```yaml
before_script:
  - echo "Logging into registry $CI_REGISTRY"
  - echo $CI_REGISTRY_PASSWORD | docker login -u $CI_REGISTRY_USER --password-stdin $CI_REGISTRY
```

### 11. Pipeline Monitoring

#### Key Metrics to Track:
- **Build Duration**: Target < 5 minutes
- **Test Coverage**: Target > 80%
- **Deployment Frequency**: Daily/Weekly
- **Failure Rate**: Target < 5%

#### GitLab Analytics:
- **Settings > Analytics > CI/CD Analytics**
- **Settings > Analytics > Repository Analytics**

### 12. Next Steps

1. ✅ Commit the updated `.gitlab-ci.yml`
2. ✅ Configure project variables
3. ✅ Enable Container Registry
4. ✅ Update environment URLs
5. ✅ Test pipeline with a small change
6. ✅ Configure deployment targets
7. ✅ Set up monitoring and alerts

### 📞 Support Resources

- **GitLab CI/CD Documentation**: https://docs.gitlab.com/ee/ci/
- **GitLab Container Registry**: https://docs.gitlab.com/ee/user/packages/container_registry/
- **Pipeline Configuration Reference**: https://docs.gitlab.com/ee/ci/yaml/

---

**Happy Deploying! 🎉**