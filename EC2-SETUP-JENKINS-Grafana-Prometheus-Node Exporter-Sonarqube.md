# EC2 Setup Guide: Jenkins, SonarQube, Grafana-Prometheus-Node Exporter

## Table of Contents
1. [Jenkins Setup](#jenkins-setup)
2. [SonarQube Setup](#sonarqube-setup)
3. [Grafana-Prometheus-Node Exporter Setup](#grafana-prometheus-node-exporter-setup)

---

## Jenkins Setup

### Jenkins Setup on AWS EC2 (Amazon Linux 2)

#### Instance Details
- **EC2 Type**: t3.large or c7i-flex.large
- **Key**: jenkins.pem
- **SG Inbound Rule**: Port 8080 Enabled
- **User**: ec2-user

#### Step 1: Connect to EC2
```bash
cd ~/Downloads
chmod 400 jenkins.pem
ssh -i "jenkins.pem" ec2-user@ec2-52-204-224-228.compute-1.amazonaws.com
```

#### Step 2: Install Dependencies
```bash
sudo yum update -y
sudo yum install wget tar tree python -y
```

#### Step 3: Install Git
```bash
sudo yum install git -y
git config --global user.name "Atul Kamble"
git config --global user.email "atul_kamble@example.com"
git config --list
```

#### Step 4: Install Docker
```bash
sudo yum install docker -y
sudo systemctl start docker
sudo systemctl enable docker
sudo docker login
docker --version
```
> **Note**: Add Jenkins user later after Jenkins installation.

#### Step 5: Install Maven
```bash
sudo yum install maven -y
mvn -v
```

#### Step 6: Install Java 21 (Amazon Corretto)
```bash
sudo yum install java-21-amazon-corretto.x86_64 -y
java --version
```

#### Step 7: Install Jenkins
```bash
sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key

sudo yum upgrade -y
sudo yum install fontconfig java-21-openjdk -y
sudo yum install jenkins -y

sudo systemctl daemon-reload
```

#### Step 8: Start & Enable Jenkins
```bash
sudo systemctl start jenkins
sudo systemctl enable jenkins
jenkins --version
```

#### Step 9: Allow Jenkins to Use Docker
```bash
sudo usermod -aG docker jenkins
sudo systemctl restart docker
sudo systemctl restart jenkins
```

#### Get Jenkins Setup Password
```bash
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

#### Access Jenkins in Browser
1. Open: `http://<EC2-Public-IP>:8080`
2. Paste password
3. Continue Setup
4. Install Suggested Plugins

#### Install Plugins Manually (If missing)
- Docker
- Docker Pipeline
- Blue Ocean
- AWS Credentials Plugin

**Restart Jenkins:**
```bash
sudo systemctl restart jenkins
```

---

## SonarQube Setup

### SonarQube on EC2 — Step-by-Step Guide

#### Prerequisites
- EC2 instance with sudo privileges
- Open port 9000 for SonarQube in the instance/security group
- At least 2–4 GB RAM (more recommended for production)
- Replace placeholder values below (Postgres password, SONAR_TOKEN)

#### 1. Update System & Install Utilities
```bash
sudo yum update -y
# or if using dnf
sudo dnf update -y
sudo yum install unzip git -y
```

#### 2. Install Java (Amazon Corretto 17)
```bash
sudo yum install java-17-amazon-corretto.x86_64 -y
java --version
```

#### 3. Install PostgreSQL 15 and Initialize DB
```bash
sudo dnf install postgresql15.x86_64 postgresql15-server -y
sudo /usr/pgsql-15/bin/postgresql-15-setup initdb   # or: sudo postgresql-setup --initdb
sudo systemctl start postgresql
sudo systemctl enable postgresql
```

##### 3.1 Set postgres Password and Create Sonar DB/User
```bash
sudo passwd postgres                # set linux postgres user password (optional)
sudo -i -u postgres psql
```

Inside psql (replace PASSWORD_HERE and sonar_user_password):
```sql
CREATE USER sonar WITH ENCRYPTED PASSWORD 'SONAR_DB_PASSWORD';
CREATE DATABASE sonarqube OWNER sonar;
\q
```
> **Note**: Don't commit or store SONAR_DB_PASSWORD in public repos.

#### 4. Download & Install SonarQube
```bash
cd /opt
sudo wget https://binaries.sonarsource.com/Distribution/sonarqube/sonarqube-10.6.0.92116.zip
sudo unzip sonarqube-10.6.0.92116.zip
sudo mv sonarqube-10.6.0.92116 sonarqube
```

#### 5. System Tuning Required by SonarQube
```bash
# increase vm.max_map_count
echo "vm.max_map_count=262144" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

# increase limits for sonar user
sudo tee -a /etc/security/limits.conf <<'EOF'
sonar   -   nofile   65536
sonar   -   nproc    4096
EOF
```

#### 6. Create Sonar System User and Set Ownership
```bash
sudo useradd -r -s /bin/false sonar   # -r creates a system user (optional - adjust flags as needed)
sudo chown -R sonar:sonar /opt/sonarqube
sudo chmod -R 755 /opt/sonarqube/bin/
sudo chmod +x /opt/sonarqube/bin/linux-x86-64/sonar.sh
```

#### 7. Configure SonarQube to Use PostgreSQL
Edit `/opt/sonarqube/conf/sonar.properties` and set the DB section (uncomment + replace values):

```properties
sonar.jdbc.username=sonar
sonar.jdbc.password=SONAR_DB_PASSWORD
sonar.jdbc.url=jdbc:postgresql://localhost:5432/sonarqube
```
Also (optional) set `sonar.web.host` and `sonar.web.port` if needed (default port 9000).

#### 8. Create Systemd Service for SonarQube
Create `/etc/systemd/system/sonarqube.service` with the content below:

```ini
[Unit]
Description=SonarQube Service
After=network.target

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

[Install]
WantedBy=multi-user.target
```

Save, then reload systemd and start SonarQube:
```bash
sudo systemctl daemon-reload
sudo systemctl reset-failed sonarqube
sudo systemctl start sonarqube
sudo systemctl enable sonarqube
sudo systemctl status sonarqube -l
```

#### 9. Verify SonarQube
- Check logs: `/opt/sonarqube/logs/` (web.log, ce.log, sonar.log, es.log)
- Open `http://<EC2_PUBLIC_IP>:9000` in browser

#### 10. Install Sonar Scanner (CLI)
```bash
cd /opt
sudo wget https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-7.3.0.5189-linux-x64.zip
sudo unzip sonar-scanner-cli-7.3.0.5189-linux-x64.zip
sudo mv sonar-scanner-7.3.0.5189-linux-x64 sonar-scanner

# add to PATH for current user (or globally in /etc/profile.d/sonar.sh)
echo 'export PATH=$PATH:/opt/sonar-scanner/bin' >> ~/.bashrc
source ~/.bashrc
sonar-scanner --version
```

#### 11. Example: Run Analysis from a Project
```bash
# export or set host/token; DO NOT expose token publicly
export SONAR_HOST_URL=http://<EC2_PUBLIC_IP>:9000
export SONAR_TOKEN=REPLACE_WITH_YOUR_TOKEN

# from project root
sonar-scanner \
  -Dsonar.projectKey=helloworld-python \
  -Dsonar.sources=. \
  -Dsonar.host.url="$SONAR_HOST_URL" \
  -Dsonar.token="$SONAR_TOKEN"
```

---

## Grafana-Prometheus-Node Exporter Setup

### Installation Guide: Grafana + Prometheus + Node Exporter (Monitoring Stack)

#### EC2 Instance Details
- **Instance Type**: t3.medium
- **OS**: Amazon Linux 2

#### Security Group Inbound Rules Required

| Port | Purpose       |
|------|---------------|
| 3000 | Grafana       |
| 9090 | Prometheus    |
| 9100 | Node Exporter |

---

### Step 1: Install Grafana Server

```bash
sudo yum update -y
sudo yum install wget tar -y
sudo yum install make -y
sudo yum install -y https://dl.grafana.com/grafana-enterprise/release/12.2.1/grafana-enterprise_12.2.1_18655849634_linux_amd64.rpm

sudo systemctl start grafana-server
sudo systemctl enable grafana-server
sudo systemctl status grafana-server

grafana-server --version
```

#### Access UI in Browser
- URL: `http://<EC2_PUBLIC_IP>:3000/`

#### Default Login
- **Username**: admin
- **Password**: admin (then set new password)
- **Example new password**: Admin@123

---

### Step 2: Install Prometheus

#### Download and Extract Prometheus
```bash
wget https://github.com/prometheus/prometheus/releases/download/v3.5.0/prometheus-3.5.0.linux-amd64.tar.gz
tar -xvf prometheus-3.5.0.linux-amd64.tar.gz
mv prometheus-3.5.0.linux-amd64 prometheus
```

#### Create Prometheus User
```bash
sudo useradd --no-create-home --shell /bin/false prometheus
```

#### Move Binaries & Set Permissions
```bash
cd prometheus
sudo cp prometheus /usr/local/bin/
sudo cp promtool /usr/local/bin/
sudo mkdir /etc/prometheus /var/lib/prometheus
sudo cp -r consoles/ console_libraries/ /etc/prometheus/
sudo cp prometheus.yml /etc/prometheus/

sudo chown -R prometheus:prometheus /etc/prometheus /var/lib/prometheus
sudo chown prometheus:prometheus /usr/local/bin/prometheus /usr/local/bin/promtool
```

#### Create Prometheus Systemd Service
```bash
sudo nano /etc/systemd/system/prometheus.service
```

Paste:
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

#### Enable & Start Service
```bash
sudo systemctl daemon-reload
sudo systemctl start prometheus
sudo systemctl enable prometheus
sudo systemctl status prometheus
```

#### Access UI
- URL: `http://<EC2_PUBLIC_IP>:9090`

---

### Step 3: Install Node Exporter (for system metrics)

```bash
wget https://github.com/prometheus/node_exporter/releases/download/v1.10.2/node_exporter-1.10.2.linux-amd64.tar.gz
tar xvf node_exporter-1.10.2.linux-amd64.tar.gz
cd node_exporter-1.10.2.linux-amd64

sudo cp node_exporter /usr/local/bin
sudo useradd node_exporter --no-create-home --shell /bin/false
sudo chown node_exporter:node_exporter /usr/local/bin/node_exporter
```

#### Create Node Exporter Service
```bash
sudo nano /etc/systemd/system/node_exporter.service
```

Paste:
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

#### Enable Service
```bash
sudo systemctl daemon-reload
sudo systemctl start node_exporter
sudo systemctl enable node_exporter
sudo systemctl status node_exporter
```

#### Verify in Browser
- URL: `http://<EC2_PUBLIC_IP>:9100/metrics`

---

### Step 4: Add Node Exporter to Prometheus Config

#### Edit Config
```bash
sudo nano /etc/prometheus/prometheus.yml
```

Add this under "scrape_configs":
```yaml
  - job_name: 'node_exporter'
    static_configs:
      - targets: ['localhost:9100']
```

#### Restart Prometheus
```bash
sudo systemctl restart prometheus
sudo systemctl status prometheus
```

---

### Final Verification

| Component     | Status Check                      | Browser URL   |
|---------------|-----------------------------------|---------------|
| Grafana       | systemctl status grafana-server   | :3000         |
| Prometheus    | systemctl status prometheus       | :9090         |
| Node Exporter | systemctl status node_exporter    | :9100/metrics |

---

### Popular Grafana Dashboard IDs

Use these dashboard IDs when importing dashboards in Grafana:

- **1860**: Node Exporter Full
- **11074**: Node Exporter for Prometheus Dashboard
- **405**: Node Exporter Server Metrics

---

### Step 5: Configure Prometheus Full Setup

#### Edit Prometheus Configuration
```bash
sudo nano /etc/prometheus/prometheus.yml
```

#### Complete Prometheus Configuration
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

**Configuration Explained:**
- `scrape_interval: 15s` - Collect metrics every 15 seconds
- `job_name` - Label to identify the metrics source
- `targets` - List of endpoints to scrape

#### Restart Prometheus
```bash
sudo systemctl restart prometheus
```

#### Verify Target is Up
1. Open Prometheus UI: `http://<EC2_PUBLIC_IP>:9090`
2. Go to Status → Targets
3. You should see both `prometheus` and `node_exporter` with status UP

---

### Step 6: Setting Up Alerts

#### Configure Alert Rules in Prometheus
```bash
sudo nano /etc/prometheus/alert_rules.yml
```

Add the following rules:
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
          summary: "High CPU usage detected"
          description: "CPU usage is above 30% (current value: {{ $value }}%)"

      - alert: HighMemoryUsage
        expr: 100 * (1 - ((node_memory_MemAvailable_bytes) / (node_memory_MemTotal_bytes))) > 80
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High memory usage detected"
          description: "Memory usage is above 80% (current value: {{ $value }}%)"

      - alert: DiskSpaceLow
        expr: 100 - ((node_filesystem_avail_bytes{mountpoint="/"} * 100) / node_filesystem_size_bytes{mountpoint="/"}) > 80
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "Disk space is low"
          description: "Disk usage is above 80% (current value: {{ $value }}%)"

      - alert: InstanceDown
        expr: up == 0
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "Instance is down"
          description: "{{ $labels.instance }} is down"
```

#### Update Prometheus Configuration
```bash
sudo nano /etc/prometheus/prometheus.yml
```

Add rule files section:
```yaml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

rule_files:
  - "alert_rules.yml"

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'node_exporter'
    static_configs:
      - targets: ['localhost:9100']
```

#### Restart Prometheus
```bash
sudo systemctl restart prometheus
```

#### Verify Alerts
1. Open Prometheus UI: `http://<EC2_PUBLIC_IP>:9090`
2. Go to Alerts
3. You should see all configured alerts

#### Configure Grafana Alerts
1. In Grafana, go to Alerting → Alert rules
2. Click Create alert rule
3. Configure based on your needs
4. Set up notification channels (Email, Slack, PagerDuty, etc.)

---

### Step 7: CPU Stress Test Script

#### Create and Configure Stress Script
```bash
sudo touch stress.sh
sudo nano stress.sh
```

Paste the following script:
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
echo "Run 'top' or 'htop' to verify CPU usage."
```

#### Make Script Executable
```bash
sudo chmod +x stress.sh
ls -l stress.sh
```

#### Run the Script
```bash
./stress.sh
```
