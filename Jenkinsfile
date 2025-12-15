pipeline {
    agent { label 'dev-server' }
    
    tools {
        maven 'myMaven'
    }
    
    environment {
        SONAR_TOKEN = credentials('sonar-token')
    }
    
    stages {
        stage("Code Clone") {
            steps {
                echo "Code Clone Stage"
                git url: "https://github.com/khushalbhavsar/DevOps-EMS-Spring-Boot-Docker-Jenkins.git", branch: "main"
            }
        }
        
        stage("Maven Build") {
            steps {
                echo "Building Java Application with Maven"
                sh "mvn clean package -DskipTests"
            }
        }

        stage("Unit Tests") {
            steps {
                echo "Running Unit Tests"
                sh "mvn test"
            }
        }
        
        stage("SonarQube Analysis") {
            steps {
                echo "Running SonarQube Analysis"
                sh """
                    mvn sonar:sonar \
                    -Dsonar.projectKey=employee-management \
                    -Dsonar.host.url=http://sonarqube:9000 \
                    -Dsonar.login=${SONAR_TOKEN}
                """
            }
        }
        
        stage("Docker Build") {
            steps {
                echo "Building Docker Image"
                sh "docker build -t employee-management ."
            }
        }
        
        stage("Push To DockerHub") {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: "dockerHubCreds",
                    usernameVariable: "dockerHubUser", 
                    passwordVariable: "dockerHubPass")]) {
                    sh 'echo $dockerHubPass | docker login -u $dockerHubUser --password-stdin'
                    sh "docker image tag employee-management:latest ${env.dockerHubUser}/employee-management:latest"
                    sh "docker push ${env.dockerHubUser}/employee-management:latest"
                }
            }
        }
        
        stage("Deploy") {
            steps {
                sh "docker compose down && docker compose up -d"
            }
        }
    }
    
    post {
        always {
            echo "Pipeline completed"
        }
        success {
            echo "✅ Build Success! Access services:"
            echo "Application: http://localhost:8080"
            echo "SonarQube: http://localhost:9000"
            echo "Prometheus: http://localhost:9090"
            echo "Grafana: http://localhost:3000 (admin/admin)"
        }
        failure {
            echo "❌ Build Failed"
        }
    }
}
