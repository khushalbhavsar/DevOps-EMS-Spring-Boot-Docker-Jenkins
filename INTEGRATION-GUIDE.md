# Docker → SonarQube → Jenkins → Prometheus → Grafana Integration Guide

## 🔗 Architecture Overview

```
Docker Compose
    ├── Employee Management App (Spring Boot) → Port 8080
    ├── SonarQube (Code Quality) → Port 9000
    ├── Prometheus (Metrics Collection) → Port 9090
    ├── Grafana (Visualization) → Port 3000
    └── PostgreSQL (Database) → Port 5432

Jenkins (External - EC2: 44.202.96.112)
    └── Triggers CI/CD Pipeline → Builds → Deploys to Docker
```

## 📋 Prerequisites

1. **Docker & Docker Compose** installed
2. **Jenkins** configured as Pipeline project (not Maven)
3. **Java 17** installed
4. **Maven** installed

---

## 🚀 Step-by-Step Setup

### 1. Start All Services

```powershell
# Start all services in detached mode
docker compose up -d

# Check service status
docker compose ps

# View logs
docker compose logs -f
```

### 2. Configure SonarQube

**Access SonarQube:**
- URL: http://localhost:9000
- Default credentials: `admin/admin`
- You'll be prompted to change password on first login

**Generate Token:**
1. Login to SonarQube
2. Go to: My Account → Security → Generate Tokens
3. Name: `jenkins-token`
4. Type: `User Token`
5. Click **Generate**
6. **Copy the token** (you won't see it again!)

**Create Project:**
1. Click **"Create Project"** → **Manually**
2. Project key: `employee-management`
3. Display name: `Employee Management System`
4. Click **Set Up**

### 3. Configure Jenkins

**Convert to Pipeline Project:**
1. Go to Jenkins → Your Job → Configure
2. Change project type to **Pipeline**
3. Under **Pipeline** section:
   - Definition: `Pipeline script from SCM`
   - SCM: `Git`
   - Repository URL: `https://github.com/khushalbhavsar/DevOps-EMS-Spring-Boot-Docker-Jenkins.git`
   - Branch: `*/main`
   - Script Path: `Jenkinsfile`

**Add SonarQube Credentials:**
1. Jenkins → Manage Jenkins → Credentials
2. Click **(global)** domain → **Add Credentials**
3. Kind: `Secret text`
4. Secret: `[paste the token from SonarQube]`
5. ID: `sonar-token`
6. Description: `SonarQube Token for Code Analysis`
7. Click **Create**

**Add Docker Hub Credentials (if not already added):**
1. Jenkins → Manage Jenkins → Credentials
2. Click **(global)** domain → **Add Credentials**
3. Kind: `Username with password`
4. Username: `[your Docker Hub username]`
5. Password: `[your Docker Hub password]`
6. ID: `dockerHubCreds`
7. Click **Create**

**Configure Maven Tool:**
1. Jenkins → Manage Jenkins → Global Tool Configuration
2. Find **Maven** section
3. Click **Add Maven**
4. Name: `myMaven` (must match Jenkinsfile)
5. Version: Select `3.9.3` or latest
6. Install automatically: ✓
7. Save

### 4. Configure Prometheus

Prometheus is already configured to scrape:
- ✅ Employee Management App (`/actuator/prometheus`)
- ✅ SonarQube (`/api/monitoring/metrics`)
- ✅ Grafana (`:3000`)
- ✅ Prometheus itself (`:9090`)

**Verify Targets:**
1. Access: http://localhost:9090
2. Go to: Status → Targets
3. All targets should show **UP** status

### 5. Configure Grafana

**Access Grafana:**
- URL: http://localhost:3000
- Default credentials: `admin/admin`
- Set new password when prompted

**Prometheus Datasource (Auto-Configured):**
The datasource is automatically provisioned via `grafana-datasource.yml`

**Verify Datasource:**
1. Grafana → Configuration (⚙️) → Data sources
2. You should see **Prometheus** listed
3. Click **Test** to verify connection

**Import Dashboard:**

**Option A - Manual Import:**
1. Click **+ (Create)** → **Import**
2. Upload `grafana-dashboard.json`
3. Select Prometheus datasource
4. Click **Import**

**Option B - Use Pre-built Dashboard:**
1. Click **+ (Create)** → **Import**
2. Enter dashboard ID: `4701` (JVM Micrometer)
3. Select Prometheus datasource
4. Click **Load** → **Import**

**Popular Spring Boot Dashboards:**
- `4701` - JVM (Micrometer)
- `6756` - Spring Boot Statistics
- `12900` - Spring Boot 2.1 System Monitor

---

## 🔄 Jenkins Pipeline Flow

```
1. Code Clone (GitHub)
   ↓
2. Maven Build (JAR creation)
   ↓
3. Unit Tests (JUnit)
   ↓
4. SonarQube Analysis (Code Quality)
   ↓
5. Docker Build (Create Image)
   ↓
6. Push to Docker Hub
   ↓
7. Deploy (docker compose up)
```

### Run Pipeline

1. Go to Jenkins → Your Job
2. Click **Build Now**
3. Monitor progress in **Console Output**

**Expected Output:**
```
✅ Code Clone Stage
✅ Maven Build Stage - JAR created
✅ Unit Tests - Tests passed
✅ SonarQube Analysis - Quality gates checked
✅ Docker Build - Image created
✅ Push To DockerHub - Image pushed
✅ Deploy - Services restarted
```

---

## 📊 Monitoring & Metrics Flow

### Data Flow:
```
Spring Boot App
    ↓ (exposes /actuator/prometheus)
Prometheus (scrapes every 15s)
    ↓ (stores metrics)
Grafana (queries Prometheus)
    ↓ (visualizes metrics)
Dashboard (displays real-time data)
```

### Key Metrics Monitored:

**Application Metrics:**
- JVM Memory (Heap/Non-Heap)
- CPU Usage
- HTTP Request Rates
- Response Times
- Active Database Connections
- Thread Count

**SonarQube Metrics:**
- Code Coverage
- Code Smells
- Bugs
- Vulnerabilities
- Technical Debt

---

## 🌐 Service URLs

| Service | URL | Credentials |
|---------|-----|-------------|
| Employee Management | http://localhost:8080 | - |
| SonarQube | http://localhost:9000 | admin/admin |
| Prometheus | http://localhost:9090 | - |
| Grafana | http://localhost:3000 | admin/admin |
| PostgreSQL | localhost:5432 | employee_user/employee_pass |

---

## 🧪 Testing the Integration

### 1. Test Application
```powershell
# Check app health
curl http://localhost:8080/actuator/health

# View Prometheus metrics
curl http://localhost:8080/actuator/prometheus
```

### 2. Test SonarQube Analysis
```powershell
# Manual SonarQube scan (from project directory)
mvn clean verify sonar:sonar `
  -Dsonar.projectKey=employee-management `
  -Dsonar.host.url=http://localhost:9000 `
  -Dsonar.login=YOUR_SONAR_TOKEN
```

### 3. Test Prometheus Scraping
1. Open: http://localhost:9090/targets
2. Verify all targets show **UP**
3. Run query: `jvm_memory_used_bytes{application="employee-management"}`

### 4. Test Grafana Dashboards
1. Open: http://localhost:3000
2. Go to **Dashboards** → **Employee Management**
3. Verify metrics are populating

### 5. Trigger Jenkins Build
```powershell
# Make a code change and commit
git add .
git commit -m "Test Jenkins integration"
git push origin main

# Or manually trigger in Jenkins UI
```

---

## 🐛 Troubleshooting

### SonarQube Not Starting
```powershell
# Check logs
docker compose logs sonarqube

# SonarQube needs ~2GB RAM
# Increase Docker memory: Docker Desktop → Settings → Resources
```

### Prometheus Not Scraping
```powershell
# Verify prometheus.yml is mounted
docker compose exec prometheus cat /etc/prometheus/prometheus.yml

# Restart Prometheus
docker compose restart prometheus
```

### Grafana Datasource Connection Failed
```powershell
# Check Prometheus is accessible from Grafana container
docker compose exec grafana ping prometheus

# Restart both services
docker compose restart prometheus grafana
```

### Jenkins Pipeline Fails at SonarQube Stage
```bash
# Verify SonarQube is accessible from Jenkins
# From Jenkins EC2 instance:
curl http://YOUR_EC2_IP:9000

# If not accessible, Jenkins needs network access to SonarQube
# Consider using SonarCloud or exposing SonarQube publicly
```

### Docker Build Fails in Jenkins
```bash
# Ensure Docker is installed on Jenkins agent
docker --version

# Check Jenkins user has Docker permissions
sudo usermod -aG docker jenkins
sudo systemctl restart jenkins
```

---

## 📝 Configuration Files

### Key Files:
- `Jenkinsfile` - CI/CD pipeline definition
- `docker-compose.yml` - Multi-container orchestration
- `prometheus.yml` - Metrics scraping configuration
- `grafana-datasource.yml` - Grafana datasource auto-config
- `pom.xml` - Maven build + SonarQube plugin config
- `application.properties` - Spring Boot + Actuator config

---

## 🔐 Security Best Practices

1. **Change Default Passwords:**
   - SonarQube: admin/admin → Change immediately
   - Grafana: admin/admin → Change immediately

2. **Use Environment Variables:**
   - Store sensitive data in `.env` file (add to `.gitignore`)
   - Use Jenkins credentials for tokens/passwords

3. **Enable HTTPS:**
   - Configure reverse proxy (nginx/traefik)
   - Use Let's Encrypt for SSL certificates

4. **Network Isolation:**
   - Use Docker networks to isolate services
   - Expose only necessary ports

---

## 📈 Next Steps

1. **Configure Quality Gates in SonarQube:**
   - Set code coverage threshold (e.g., >80%)
   - Define acceptable bug/vulnerability counts

2. **Set Up Alerts in Grafana:**
   - Configure notification channels (Slack, Email)
   - Create alert rules for critical metrics

3. **Add More Dashboards:**
   - Business metrics (employees created, deleted)
   - Performance metrics (response time percentiles)
   - Infrastructure metrics (Docker container stats)

4. **Integrate with GitHub:**
   - Add SonarQube PR decoration
   - Set up GitHub Actions as alternative to Jenkins
   - Enable branch protection rules

---

## 🎯 Success Criteria

Your integration is successful when:
- ✅ All Docker services are running (`docker compose ps`)
- ✅ SonarQube analyzes code on every commit
- ✅ Prometheus scrapes metrics every 15s
- ✅ Grafana displays real-time application metrics
- ✅ Jenkins pipeline completes all stages successfully
- ✅ Docker images are built and pushed to Docker Hub
- ✅ Application deploys automatically after successful build

---

## 📚 Additional Resources

- [SonarQube Documentation](https://docs.sonarqube.org/)
- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)
- [Spring Boot Actuator](https://docs.spring.io/spring-boot/docs/current/reference/html/actuator.html)
- [Jenkins Pipeline Syntax](https://www.jenkins.io/doc/book/pipeline/syntax/)

---

**Happy Monitoring! 🚀**
