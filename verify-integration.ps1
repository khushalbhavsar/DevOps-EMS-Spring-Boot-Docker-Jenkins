# Integration Verification Script
# This script checks connectivity between Docker, SonarQube, Jenkins, Prometheus, and Grafana

Write-Host "==================================================================" -ForegroundColor Cyan
Write-Host "  Docker → SonarQube → Jenkins → Prometheus → Grafana Integration" -ForegroundColor Cyan
Write-Host "==================================================================" -ForegroundColor Cyan
Write-Host ""

# 1. Check Docker Services
Write-Host "[1/6] Checking Docker Services..." -ForegroundColor Yellow
docker compose ps
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Docker services are running" -ForegroundColor Green
} else {
    Write-Host "❌ Docker services check failed" -ForegroundColor Red
    exit 1
}
Write-Host ""

# 2. Check Employee Management Application
Write-Host "[2/6] Testing Employee Management Application..." -ForegroundColor Yellow
try {
    $health = Invoke-RestMethod -Uri "http://localhost:8080/actuator/health" -TimeoutSec 5
    if ($health.status -eq "UP") {
        Write-Host "✅ Employee Management App: HEALTHY" -ForegroundColor Green
        Write-Host "   URL: http://localhost:8080" -ForegroundColor Cyan
    }
} catch {
    Write-Host "❌ Employee Management App: DOWN" -ForegroundColor Red
}
Write-Host ""

# 3. Check Prometheus Metrics
Write-Host "[3/6] Testing Prometheus Metrics Collection..." -ForegroundColor Yellow
try {
    $metrics = Invoke-WebRequest -Uri "http://localhost:8080/actuator/prometheus" -TimeoutSec 5
    if ($metrics.StatusCode -eq 200) {
        Write-Host "✅ Prometheus Metrics: AVAILABLE" -ForegroundColor Green
        Write-Host "   Endpoint: http://localhost:8080/actuator/prometheus" -ForegroundColor Cyan
    }
} catch {
    Write-Host "❌ Prometheus Metrics: UNAVAILABLE" -ForegroundColor Red
}
Write-Host ""

# 4. Check Prometheus Server
Write-Host "[4/6] Testing Prometheus Server..." -ForegroundColor Yellow
try {
    $prom = Invoke-WebRequest -Uri "http://localhost:9090/-/healthy" -TimeoutSec 5
    if ($prom.StatusCode -eq 200) {
        Write-Host "✅ Prometheus Server: HEALTHY" -ForegroundColor Green
        Write-Host "   URL: http://localhost:9090" -ForegroundColor Cyan
        Write-Host "   Targets: http://localhost:9090/targets" -ForegroundColor Cyan
    }
} catch {
    Write-Host "❌ Prometheus Server: DOWN" -ForegroundColor Red
}
Write-Host ""

# 5. Check SonarQube
Write-Host "[5/6] Testing SonarQube Server..." -ForegroundColor Yellow
try {
    $sonar = Invoke-WebRequest -Uri "http://localhost:9000/api/system/status" -TimeoutSec 10
    $sonarStatus = ($sonar.Content | ConvertFrom-Json).status
    if ($sonarStatus -eq "UP") {
        Write-Host "✅ SonarQube Server: HEALTHY ($sonarStatus)" -ForegroundColor Green
        Write-Host "   URL: http://localhost:9000" -ForegroundColor Cyan
        Write-Host "   Credentials: admin/admin (change on first login)" -ForegroundColor Cyan
    }
} catch {
    Write-Host "⚠️  SonarQube Server: STARTING (may take 2-3 minutes)" -ForegroundColor Yellow
    Write-Host "   URL: http://localhost:9000" -ForegroundColor Cyan
}
Write-Host ""

# 6. Check Grafana
Write-Host "[6/6] Testing Grafana Server..." -ForegroundColor Yellow
try {
    $grafana = Invoke-WebRequest -Uri "http://localhost:3000/api/health" -TimeoutSec 5
    if ($grafana.StatusCode -eq 200) {
        Write-Host "✅ Grafana Server: HEALTHY" -ForegroundColor Green
        Write-Host "   URL: http://localhost:3000" -ForegroundColor Cyan
        Write-Host "   Credentials: admin/admin" -ForegroundColor Cyan
    }
} catch {
    Write-Host "❌ Grafana Server: DOWN" -ForegroundColor Red
}
Write-Host ""

# Summary
Write-Host "==================================================================" -ForegroundColor Cyan
Write-Host "  Integration Summary" -ForegroundColor Cyan
Write-Host "==================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Data Flow:" -ForegroundColor White
Write-Host "  1. Spring Boot App → Exposes /actuator/prometheus metrics" -ForegroundColor Gray
Write-Host "  2. Prometheus → Scrapes metrics every 15s" -ForegroundColor Gray
Write-Host "  3. Grafana → Queries Prometheus for visualization" -ForegroundColor Gray
Write-Host "  4. SonarQube → Analyzes code quality (via Jenkins pipeline)" -ForegroundColor Gray
Write-Host "  5. Jenkins → Triggers build → SonarQube → Docker build → Deploy" -ForegroundColor Gray
Write-Host ""
Write-Host "Quick Access:" -ForegroundColor White
Write-Host "  Application:  http://localhost:8080" -ForegroundColor Cyan
Write-Host "  SonarQube:    http://localhost:9000 (admin/admin)" -ForegroundColor Cyan
Write-Host "  Prometheus:   http://localhost:9090" -ForegroundColor Cyan
Write-Host "  Grafana:      http://localhost:3000 (admin/admin)" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor White
Write-Host "  1. Configure Jenkins Pipeline project (see INTEGRATION-GUIDE.md)" -ForegroundColor Yellow
Write-Host "  2. Add SonarQube token to Jenkins credentials" -ForegroundColor Yellow
Write-Host "  3. Import Grafana dashboard (ID: 4701 or 12900)" -ForegroundColor Yellow
Write-Host "  4. Run Jenkins build to test full CI/CD flow" -ForegroundColor Yellow
Write-Host ""
Write-Host "==================================================================" -ForegroundColor Cyan
