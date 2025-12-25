# EC2 Setup: Jenkins, Grafana, Prometheus, Node Exporter & SonarQube

Complete DevOps monitoring and CI/CD stack setup guide for Amazon Linux 2 EC2 instances.

---

## 📋 Table of Contents

1. [Jenkins Setup](#jenkins-setup)
2. [SonarQube Setup](#sonarqube-setup)
3. [Grafana & Prometheus Setup](#grafana--prometheus-setup)
4. [Node Exporter Setup](#node-exporter-setup)
5. [Alert Configuration](#alert-configuration)
6. [Testing & Verification](#testing--verification)

---

## 🔧 Jenkins Setup

### 📌 Prerequisites

| Resource | Requirement |
|----------|-------------|
| **EC2 Instance Type** | t3.large recommended |
| **OS** | Amazon Linux 2023 |
| **Storage** | 30 GB SSD |
| **Key Pair** | jenkins.pem |

### 🔓 Security Group - Inbound Rules

| Port | Protocol | Purpose |
|------|----------|---------|
| 22 | TCP | SSH |
| 80 | TCP | HTTP |
| 443 | TCP | HTTPS |
| 8080 | TCP | Jenkins UI |

### ⚙️ Step 1: Connect to EC2 Instance

```bash
cd Downloads
chmod 400 jenkins.pem
ssh -i "jenkins.pem" ec2-user@<YOUR_EC2_PUBLIC_IP>
```

### 📦 Step 2: Install Required Packages

#### 2.1 Update and Install Git

```bash
sudo yum update -y
sudo yum install git -y
git --version
```

#### 2.2 Configure Git (Optional)

```bash
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
git config --list
```

#### 2.3 Install Docker

```bash
sudo yum install docker -y
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker ec2-user
docker --version
```

#### 2.4 Install Java 21 (Amazon Corretto)

```bash
# Option 1: Amazon Corretto
sudo dnf install java-21-amazon-corretto -y

# Option 2: OpenJDK
sudo yum install java-21-openjdk -y

java --version
```

#### 2.5 Install Maven

```bash
sudo yum install maven -y
mvn -v
```

#### 2.6 Install Jenkins via YUM Repository

```bash
sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
sudo yum upgrade -y
sudo yum install jenkins -y
jenkins --version
```

#### 2.7 Add Jenkins User to Docker Group

```bash
sudo usermod -aG docker jenkins
```

### ▶️ Step 3: Start Jenkins Service

```bash
sudo systemctl start jenkins
sudo systemctl enable jenkins
sudo systemctl status jenkins
```

### 🌐 Step 4: Access Jenkins Web UI

1. Open browser and navigate to:
   ```
   http://<YOUR_EC2_PUBLIC_IP>:8080
   ```

2. Retrieve initial admin password:
   ```bash
   sudo cat /var/lib/jenkins/secrets/initialAdminPassword
   ```

3. Paste the password in Jenkins setup screen
4. Complete initial configuration

### 🐳 Alternative: Jenkins via Docker

```bash
# Pull Jenkins image with JDK 21
sudo docker pull jenkins/jenkins:jdk21

# Run Jenkins container
sudo docker run -d \
  --name jenkins \
  -p 8080:8080 \
  -p 50000:50000 \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v jenkins_home:/var/jenkins_home \
  jenkins/jenkins:jdk21

# List containers
sudo docker container ls

# Get initial admin password
sudo docker exec -it <CONTAINER_ID> cat /var/jenkins_home/secrets/initialAdminPassword
```

---

## ☁️ SonarQube Setup

### 📌 Prerequisites

- **Instance Type**: t2.medium / t3.medium (minimum 4GB RAM)
- **OS**: Amazon Linux 2
- **Port Required**: 9000
- **Storage**: 20GB SSD
- **Key Pair**: sonar.pem

### ⚙️ Step 1: Update System Packages

```bash
sudo yum update -y
sudo dnf update -y
sudo yum install unzip wget -y
```

### 2️⃣ Step 2: Install Java 17

```bash
sudo yum search java-17
sudo yum install java-17-amazon-corretto.x86_64 -y
java --version
```

### 3️⃣ Step 3: Install & Configure PostgreSQL 15

```bash
# Install PostgreSQL
sudo dnf install postgresql15.x86_64 postgresql15-server -y
sudo postgresql-setup --initdb

# Start and enable service
sudo systemctl start postgresql
sudo systemctl enable postgresql
sudo systemctl status postgresql
```

### 4️⃣ Step 4: Create SonarQube Database & User

```bash
# Set PostgreSQL password
sudo passwd postgres
# Set password: Admin@123 (retype)

# Login as postgres user
sudo -i -u postgres psql
```

Run SQL commands in PostgreSQL shell:

```sql
ALTER USER postgres WITH PASSWORD 'Admin@1234';
CREATE DATABASE sonarqube;
CREATE USER sonar WITH ENCRYPTED PASSWORD 'Sonar@123';
GRANT ALL PRIVILEGES ON DATABASE sonarqube TO sonar;
\q
```

### 5️⃣ Step 5: Download & Install SonarQube

```bash
cd /opt
sudo wget https://binaries.sonarsource.com/Distribution/sonarqube/sonarqube-10.6.0.92116.zip
sudo unzip sonarqube-10.6.0.92116.zip
sudo mv sonarqube-10.6.0.92116 sonarqube
cd sonarqube
```

### 6️⃣ Step 6: Configure System Limits

```bash
# Set kernel parameters
echo "vm.max_map_count=262144" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

# Set file descriptor limits
sudo tee -a /etc/security/limits.conf <<EOF
sonar   -   nofile   65536
sonar   -   nproc    4096
EOF
```

### 7️⃣ Step 7: Configure SonarQube Database Settings

```bash
sudo nano /opt/sonarqube/conf/sonar.properties
```

Add the following configuration:

```properties
sonar.jdbc.username=sonar
sonar.jdbc.password=Sonar@123
sonar.jdbc.url=jdbc:postgresql://localhost:5432/sonarqube
sonar.search.javaopts=-Xmx512m -Xms512m -XX:MaxDirectMemorySize=256m
```

### 8️⃣ Step 8: Create SonarQube System User

```bash
sudo useradd sonar
sudo chown -R sonar:sonar /opt/sonarqube
sudo chmod -R 755 /opt/sonarqube/bin/
```

### 9️⃣ Step 9: Create Systemd Service File

```bash
sudo nano /etc/systemd/system/sonarqube.service
```

Paste the following configuration:

```ini
[Unit]
Description=SonarQube LTS Service
After=network.target postgresql.service

[Service]
Type=forking
User=sonar
Group=sonar
LimitNOFILE=65536
LimitNPROC=4096

Environment="JAVA_HOME=/usr/lib/jvm/java-17-amazon-corretto.x86_64"
Environment="PATH=/usr/lib/jvm/java-17-amazon-corretto.x86_64/bin:/usr/local/bin:/usr/bin:/bin"

ExecStart=/opt/sonarqube/bin/linux-x86-64/sonar.sh start
ExecStop=/opt/sonarqube/bin/linux-x86-64/sonar.sh stop

Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

### 🔟 Step 10: Set Permissions & Start Service

```bash
sudo chmod +x /opt/sonarqube/bin/linux-x86-64/sonar.sh
sudo chmod -R 755 /opt/sonarqube/bin/
sudo chown -R sonar:sonar /opt/sonarqube

# Reload systemd and start service
sudo systemctl reset-failed sonarqube
sudo systemctl daemon-reload
sudo systemctl start sonarqube
sudo systemctl enable sonarqube
sudo systemctl status sonarqube -l
```

### 💻 Access SonarQube Web UI

```
URL: http://<EC2_PUBLIC_IP>:9000
Default Login:
  Username: admin
  Password: admin
```

First login will prompt you to change the default password.

---

## 📊 Grafana & Prometheus Setup

### 📌 Prerequisites

| Resource | Requirement |
|----------|-------------|
| **Instance Type** | t3.medium (minimum 2GB RAM) |
| **OS** | Amazon Linux 2 |
| **Ports** | 3000 (Grafana), 9090 (Prometheus), 9100 (Node Exporter) |

### 🔓 Security Group - Inbound Rules

| Port | Purpose |
|------|---------|
| 3000 | Grafana Web UI |
| 9090 | Prometheus Web UI |
| 9100 | Node Exporter Metrics |

### ⚙️ Step 1: Install Grafana Server

```bash
# Update system
sudo yum update -y
sudo yum install wget tar make -y

# Install Grafana Enterprise
sudo yum install -y https://dl.grafana.com/grafana-enterprise/release/12.2.1/grafana-enterprise_12.2.1_18655849634_linux_amd64.rpm

# Start and enable service
sudo systemctl start grafana-server
sudo systemctl enable grafana-server
sudo systemctl status grafana-server

# Verify version
grafana-server --version
```

**Access Grafana Web UI:**
```
URL: http://<EC2_PUBLIC_IP>:3000/
Username: admin
Password: admin (change on first login)
```

### 📈 Step 2: Install Prometheus

#### 2.1 Download and Extract Prometheus

```bash
cd /tmp
wget https://github.com/prometheus/prometheus/releases/download/v3.5.0/prometheus-3.5.0.linux-amd64.tar.gz
tar -xvf prometheus-3.5.0.linux-amd64.tar.gz
mv prometheus-3.5.0.linux-amd64 prometheus
cd prometheus
```

#### 2.2 Create Prometheus User

```bash
sudo useradd --no-create-home --shell /bin/false prometheus
```

#### 2.3 Set Up Prometheus Files

```bash
cd /tmp/prometheus

# Copy binaries
sudo cp prometheus /usr/local/bin/
sudo cp promtool /usr/local/bin/

# Create directories
sudo mkdir -p /etc/prometheus /var/lib/prometheus

# Copy configuration files
sudo cp -r consoles/ console_libraries/ /etc/prometheus/
sudo cp prometheus.yml /etc/prometheus/

# Set permissions
sudo chown -R prometheus:prometheus /etc/prometheus /var/lib/prometheus
sudo chown prometheus:prometheus /usr/local/bin/prometheus /usr/local/bin/promtool
```

#### 2.4 Create Prometheus Systemd Service

```bash
sudo nano /etc/systemd/system/prometheus.service
```

Paste the following:

```ini
[Unit]
Description=Prometheus Monitoring
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/usr/local/bin/prometheus \
  --config.file=/etc/prometheus/prometheus.yml \
  --storage.tsdb.path=/var/lib/prometheus \
  --web.console.templates=/etc/prometheus/consoles \
  --web.console.libraries=/etc/prometheus/console_libraries

[Install]
WantedBy=multi-user.target
```

#### 2.5 Start Prometheus Service

```bash
sudo systemctl daemon-reload
sudo systemctl start prometheus
sudo systemctl enable prometheus
sudo systemctl status prometheus
```

**Access Prometheus Web UI:**
```
URL: http://<EC2_PUBLIC_IP>:9090
```

---

## 🖥️ Node Exporter Setup

### ⚙️ Installation Steps

```bash
cd /tmp
wget https://github.com/prometheus/node_exporter/releases/download/v1.10.2/node_exporter-1.10.2.linux-amd64.tar.gz
tar xvf node_exporter-1.10.2.linux-amd64.tar.gz
cd node_exporter-1.10.2.linux-amd64

# Copy binary
sudo cp node_exporter /usr/local/bin

# Create user
sudo useradd node_exporter --no-create-home --shell /bin/false

# Set permissions
sudo chown node_exporter:node_exporter /usr/local/bin/node_exporter
```

### Create Node Exporter Service

```bash
sudo nano /etc/systemd/system/node_exporter.service
```

Paste the following:

```ini
[Unit]
Description=Node Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=/usr/local/bin/node_exporter

[Install]
WantedBy=multi-user.target
```

### Start Node Exporter Service

```bash
sudo systemctl daemon-reload
sudo systemctl start node_exporter
sudo systemctl enable node_exporter
sudo systemctl status node_exporter
```

**Verify Metrics:**
```
URL: http://<EC2_PUBLIC_IP>:9100/metrics
```

### Add Node Exporter to Prometheus

Edit Prometheus configuration:

```bash
sudo nano /etc/prometheus/prometheus.yml
```

Add this under `scrape_configs`:

```yaml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'node_exporter'
    static_configs:
      - targets: ['localhost:9100']
```

Restart Prometheus:

```bash
sudo systemctl restart prometheus
sudo systemctl status prometheus
```

---

## 🚨 Alert Configuration

### ⚙️ Step 1: Create Alert Rules

```bash
sudo nano /etc/prometheus/alert_rules.yml
```

Add the following alert rules:

```yaml
groups:
  - name: node_alerts
    interval: 30s
    rules:
      
      - alert: HighCPUUsage
        expr: 100 - (avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 30
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High CPU usage detected on {{ $labels.instance }}"
          description: "CPU usage is above 30% (current: {{ $value | humanizePercentage }})"

      - alert: HighMemoryUsage
        expr: 100 * (1 - ((node_memory_MemAvailable_bytes) / (node_memory_MemTotal_bytes))) > 80
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High memory usage on {{ $labels.instance }}"
          description: "Memory usage is above 80% (current: {{ $value | humanize }}%)"

      - alert: DiskSpaceLow
        expr: 100 - ((node_filesystem_avail_bytes{mountpoint="/"} * 100) / node_filesystem_size_bytes{mountpoint="/"}) > 80
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "Disk space low on {{ $labels.instance }}"
          description: "Disk usage is above 80% (current: {{ $value | humanize }}%)"

      - alert: InstanceDown
        expr: up == 0
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "Instance {{ $labels.instance }} is down"
          description: "{{ $labels.instance }} has been down for more than 1 minute"
```

### 📝 Step 2: Update Prometheus Configuration

```bash
sudo nano /etc/prometheus/prometheus.yml
```

Update to include alert rules:

```yaml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

rule_files:
  - "alert_rules.yml"

alerting:
  alertmanagers:
    - static_configs:
        - targets: []

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'node_exporter'
    static_configs:
      - targets: ['localhost:9100']
```

### 🔄 Restart Prometheus

```bash
sudo systemctl restart prometheus
sudo systemctl status prometheus
```

### Verify Alerts

1. Open Prometheus: http://<EC2_PUBLIC_IP>:9090
2. Go to **Alerts** tab
3. All configured alerts should be listed

---

## 🧪 Testing & Verification

### Component Status Check

| Component | Status Command | Browser URL |
|-----------|-----------------|-------------|
| **Jenkins** | `sudo systemctl status jenkins` | http://IP:8080 |
| **SonarQube** | `sudo systemctl status sonarqube` | http://IP:9000 |
| **Prometheus** | `sudo systemctl status prometheus` | http://IP:9090 |
| **Grafana** | `sudo systemctl status grafana-server` | http://IP:3000 |
| **Node Exporter** | `sudo systemctl status node_exporter` | http://IP:9100/metrics |

### Verify Prometheus Targets

1. Open Prometheus: http://<EC2_PUBLIC_IP>:9090
2. Go to **Status → Targets**
3. Verify all targets show **UP** status

### Import Grafana Dashboards

Popular dashboard IDs:
- **1860**: Node Exporter Full
- **11074**: Node Exporter for Prometheus
- **405**: Node Exporter Server Metrics

**Steps:**
1. Open Grafana: http://<EC2_PUBLIC_IP>:3000
2. Click **+** → **Import**
3. Enter dashboard ID
4. Select Prometheus datasource
5. Click **Import**

### CPU Stress Test

Create a test script to verify alerts:

```bash
sudo nano stress.sh
```

Paste the script:

```bash
#!/bin/bash

echo "===== CPU Utilization Booster ====="
echo "This script will increase CPU usage beyond 80%"
echo "Press CTRL + C to stop."

# Detect number of CPU cores
CORES=$(nproc)
echo "Detected CPU Cores: $CORES"

# Start load on all cores
for i in $(seq 1 $CORES); do
  while true; do :; done &
done

echo "CPU load started on all $CORES cores..."
echo "Monitor with: top or htop"
```

Make executable and run:

```bash
sudo chmod +x stress.sh
./stress.sh
```

Monitor CPU usage:
```bash
top
# or
htop
```

Stop the stress test:
```bash
# Press Ctrl+C or kill the process
pkill -f "while true"
```

---

## 🔒 Security Best Practices

1. **Change default passwords** for all services
2. **Enable firewall rules** and restrict port access
3. **Use SSL/TLS certificates** for production
4. **Set up authentication** for Jenkins and SonarQube
5. **Regularly update** all packages and services
6. **Monitor logs** for security issues
7. **Backup database** regularly

---

## 📚 Additional Resources

- [Jenkins Documentation](https://www.jenkins.io/doc/)
- [SonarQube Setup Guide](https://docs.sonarqube.org/)
- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)
- [Node Exporter Guide](https://github.com/prometheus/node_exporter)

---

**Last Updated**: December 25, 2025  
**Version**: 2.0.0
