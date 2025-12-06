pipeline {
    agent { label 'dev-server' }
    
    tools {
        maven 'myMaven'
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
                sh "docker compose down && docker compose up -d --build"
            }
        }
    }
}
