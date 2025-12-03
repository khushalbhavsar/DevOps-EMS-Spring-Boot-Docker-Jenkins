# Employee Management System

A modern, full-stack Employee Management System built with **Spring Boot**, **Maven**, and **H2 Database**. Features a beautiful web interface, REST API, and comprehensive CRUD operations for managing employees efficiently.

## 🌟 Features

### 🌐 Web Interface
- **Modern, Responsive UI** - Beautiful gradient design that works on all devices
- **Complete CRUD Operations** - Add, edit, delete, and view employees
- **Real-time Search & Filter** - Search across all employee fields instantly
- **Form Validation** - Client-side validation for all input fields
- **Status Notifications** - User feedback for all operations
- **Mobile-Friendly** - Fully responsive design for desktop, tablet, and mobile

### 🔌 REST API
- **RESTful Endpoints** - Standard HTTP methods for all operations
- **JSON Data Format** - Easy integration with other applications
- **CORS Enabled** - Cross-origin requests supported
- **Error Handling** - Proper HTTP status codes and error responses

### 🗄️ Database
- **H2 In-Memory Database** - Perfect for development and testing
- **JPA/Hibernate** - Object-relational mapping for easy data management
- **Database Console** - Built-in H2 console for direct database access
- **Auto DDL** - Database schema created automatically

### 🚀 DevOps Ready
- **Docker Support** - Containerization ready
- **CI/CD Pipelines** - Jenkins and GitLab CI configurations
- **Maven Build** - Reliable build system with wrapper
- **Production Ready** - Configured for deployment

## 🚀 Quick Start

### Prerequisites
- **Java 21+** (JDK 21 recommended)
- **Maven 3.6+** (wrapper included)

### 1. Clone & Build
```bash
git clone <repository-url>
cd employee-management-system
./mvnw clean package
```

### 2. Run Application
```bash
java -jar target/employee-management-0.0.1-SNAPSHOT.jar
```

### 3. Access Application
- **🌐 Web Interface**: `http://localhost:8080/`
- **🔌 API Base URL**: `http://localhost:8080/api/employees`
- **🗄️ H2 Console**: `http://localhost:8080/h2-console`

## 📖 API Documentation

### Base URL: `/api/employees`

| Method | Endpoint | Description | Request Body |
|--------|----------|-------------|--------------|
| `GET` | `/` | List all employees | - |
| `GET` | `/{id}` | Get employee by ID | - |
| `POST` | `/` | Create new employee | Employee JSON |
| `PUT` | `/{id}` | Update employee | Employee JSON |
| `DELETE` | `/{id}` | Delete employee | - |

### Employee JSON Structure
```json
{
  "id": 1,
  "firstName": "John",
  "lastName": "Doe", 
  "email": "john.doe@example.com",
  "role": "Software Engineer"
}
```

### API Examples

#### Create Employee
```bash
curl -X POST http://localhost:8080/api/employees \
  -H "Content-Type: application/json" \
  -d '{"firstName":"John","lastName":"Doe","email":"john.doe@example.com","role":"Developer"}'
```

#### Get All Employees
```bash
curl http://localhost:8080/api/employees
```

#### Update Employee
```bash
curl -X PUT http://localhost:8080/api/employees/1 \
  -H "Content-Type: application/json" \
  -d '{"firstName":"John","lastName":"Smith","email":"john.smith@example.com","role":"Senior Developer"}'
```

#### Delete Employee
```bash
curl -X DELETE http://localhost:8080/api/employees/1
```

## 🗄️ Database Configuration

### H2 Console Access
- **URL**: `http://localhost:8080/h2-console`
- **JDBC URL**: `jdbc:h2:mem:employeedb`
- **Username**: `SA`
- **Password**: (leave empty)

### Database Properties
```properties
spring.h2.console.enabled=true
spring.datasource.url=jdbc:h2:mem:employeedb;DB_CLOSE_DELAY=-1;DB_CLOSE_ON_EXIT=FALSE
spring.datasource.driver-class-name=org.h2.Driver
spring.jpa.database-platform=org.hibernate.dialect.H2Dialect
spring.jpa.hibernate.ddl-auto=update
```

## 🐳 Docker

### Build Image
```bash
docker build -t employee-management:latest .
```

### Run Container
```bash
docker run -p 8080:8080 employee-management:latest
```

### Docker Compose (Optional)
```yaml
version: '3.8'
services:
  employee-management:
    build: .
    ports:
      - "8080:8080"
    environment:
      - SPRING_PROFILES_ACTIVE=docker
```

## 🔧 Development

### Project Structure
```
employee-management/
├── src/
│   ├── main/
│   │   ├── java/com/example/
│   │   │   ├── EmployeeManagementApplication.java
│   │   │   ├── controller/EmployeeController.java
│   │   │   ├── model/Employee.java
│   │   │   ├── repository/EmployeeRepository.java
│   │   │   └── service/EmployeeService.java
│   │   └── resources/
│   │       ├── application.properties
│   │       └── static/
│   │           ├── index.html
│   │           ├── script.js
│   │           └── styles.css
│   └── test/
├── Dockerfile
├── Jenkinsfile
├── .gitlab-ci.yml
├── pom.xml
└── README.md
```

### Technologies Used
- **Backend**: Spring Boot 3.1.4, Spring Data JPA, Spring Web
- **Database**: H2 Database (in-memory)
- **Frontend**: HTML5, CSS3, JavaScript (Vanilla)
- **Build Tool**: Maven 3.9+
- **Java Version**: 21+
- **Server**: Embedded Tomcat

### Running in Development Mode
```bash
./mvnw spring-boot:run
```

### Running Tests
```bash
./mvnw test
```

## 🚀 CI/CD Pipelines

### Jenkins Pipeline
The `Jenkinsfile` includes:
- **Checkout** - Get source code
- **Build** - Compile and package
- **Test** - Run unit tests
- **Docker Build** - Create container image
- **Artifacts** - Archive JAR files

### GitLab CI Pipeline
The `.gitlab-ci.yml` includes:
- **Build Stage** - Maven compile and package
- **Test Stage** - Execute test suite
- **Docker Stage** - Build and tag container image

### Pipeline Configuration
```bash
# Enable push stage in Jenkinsfile
# Set registry credentials in GitLab CI/CD variables
# Configure Docker registry access
```

## 🖥️ Jenkins Setup on AWS EC2 (Amazon Linux 2)

### Instance Details
- **EC2 Type**: t3.large or c7i-flex.large
- **Key**: jenkins.pem
- **SG Inbound Rule**: Port 8080 Enabled
- **User**: ec2-user

### Step 1: Connect to EC2
```bash
cd ~/Downloads
chmod 400 jenkins.pem
ssh -i "jenkins.pem" ec2-user@ec2-52-204-224-228.compute-1.amazonaws.com
```

### Step 2: Install Dependencies
```bash
sudo yum update -y
sudo yum install wget tar tree python -y
```

### Step 3: Install Git
```bash
sudo yum install git -y
git config --global user.name "khushalbhavsar"
git config --global user.email "khushalbhavsar41@gmail.com"
git config --list
```

### Step 4: Install Docker
```bash
sudo yum install docker -y
sudo systemctl start docker
sudo systemctl enable docker
sudo docker login
docker --version
```
**Note**: Add Jenkins user later after Jenkins installation.

### Step 5: Install Maven
```bash
sudo yum install maven -y
mvn -v
```

### Step 6: Install Java 21 (Amazon Corretto)
```bash
sudo yum install java-21-amazon-corretto.x86_64 -y
java --version
```

### Step 7: Install Jenkins
```bash
sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
sudo yum upgrade -y
sudo yum install fontconfig java-21-openjdk -y
sudo yum install jenkins -y
sudo systemctl daemon-reload
```

### Step 8: Start & Enable Jenkins
```bash
sudo systemctl start jenkins
sudo systemctl enable jenkins
jenkins --version
```

### Step 9: Allow Jenkins to Use Docker
```bash
sudo usermod -aG docker jenkins
sudo systemctl restart docker
sudo systemctl restart jenkins
```

### Get Jenkins Setup Password
```bash
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

### Access Jenkins in Browser
1. Open: `http://<EC2-Public-IP>:8080`
2. Paste password
3. Continue Setup
4. Install Suggested Plugins

### Install Plugins Manually (If missing)
- Docker
- Docker Pipeline
- Blue Ocean
- AWS Credentials Plugin

### Restart Jenkins
```bash
sudo systemctl restart jenkins
```

## 🎨 Web Interface Features

### User Experience
- **Intuitive Design** - Easy-to-use interface for all skill levels
- **Keyboard Shortcuts** - `Ctrl+Enter` to submit, `Escape` to clear
- **Loading Indicators** - Visual feedback during operations
- **Error Handling** - Comprehensive error messages and recovery
- **Auto-refresh** - Optional automatic data refresh

### Responsive Design
- **Desktop** - Full-featured interface with sidebar layout
- **Tablet** - Optimized layout for medium screens
- **Mobile** - Touch-friendly interface with stacked layout

## 🔐 Security Features

- **Input Validation** - Frontend and backend validation
- **XSS Protection** - HTML escaping for user inputs
- **CORS Configuration** - Controlled cross-origin access
- **Error Handling** - Secure error messages without sensitive data

## 🔧 Configuration

### Environment Variables
```bash
export JAVA_HOME=/path/to/java
export SPRING_PROFILES_ACTIVE=production
export SERVER_PORT=8080
```

### Application Profiles
- **Default** - Development with H2 database
- **Production** - Can be configured for external database
- **Test** - Test-specific configurations

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Support

For support and questions:
- Create an issue in the repository
- Check the H2 console for database-related issues
- Verify Java version compatibility
- Check application logs for error details

## 🚀 Future Enhancements

- **Authentication & Authorization** - User login and role-based access
- **Database Migration** - Support for MySQL/PostgreSQL
- **Advanced Search** - Complex filtering and sorting
- **File Upload** - Employee photo and document management
- **Reporting** - Export employees to PDF/Excel
- **Audit Trail** - Track all data changes
- **Performance Monitoring** - Application metrics and monitoring