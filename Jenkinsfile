pipeline {
    agent { label 'dev-server' }

    tools {
        maven 'myMaven'
    }

    environment {
        SONAR_TOKEN = credentials('sonar-token')
        IMAGE_NAME  = "employee-management"
        DOCKER_TAG  = "${BUILD_NUMBER}"
    }

    stages {

        stage('Checkout Source') {
            steps {
                echo "📥 Checking out source code from Jenkins SCM"
                checkout scm
            }
        }

        stage('Maven Build') {
            steps {
                echo "🔨 Building Java Application"
                sh 'mvn clean package -DskipTests'
            }
        }

        stage('Unit Tests') {
            steps {
                echo "🧪 Running Unit Tests"
                sh 'mvn test'
            }
        }

        stage('SonarQube Analysis') {
            steps {
                echo "🔍 Running SonarQube Analysis"
                sh """
                mvn sonar:sonar \
                  -Dsonar.projectKey=employee-management \
                  -Dsonar.host.url=http://localhost:9000 \
                  -Dsonar.token=${SONAR_TOKEN}
                """
            }
        }

        stage('Docker Build') {
            steps {
                echo "🐳 Building Docker Image"
                sh """
                docker build -t ${IMAGE_NAME}:${DOCKER_TAG} .
                docker tag ${IMAGE_NAME}:${DOCKER_TAG} ${IMAGE_NAME}:latest
                """
            }
        }

        stage('Push Image to DockerHub') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'dockerHubCreds',
                    usernameVariable: 'DOCKER_USER',
                    passwordVariable: 'DOCKER_PASS'
                )]) {
                    sh """
                    echo "${DOCKER_PASS}" | docker login -u "${DOCKER_USER}" --password-stdin
                    docker tag ${IMAGE_NAME}:${DOCKER_TAG} ${DOCKER_USER}/${IMAGE_NAME}:${DOCKER_TAG}
                    docker tag ${IMAGE_NAME}:${DOCKER_TAG} ${DOCKER_USER}/${IMAGE_NAME}:latest
                    docker push ${DOCKER_USER}/${IMAGE_NAME}:${DOCKER_TAG}
                    docker push ${DOCKER_USER}/${IMAGE_NAME}:latest
                    docker logout
                    """
                }
            }
        }

        stage('Deploy Application') {
            steps {
                echo "🚀 Deploying Application using Docker Compose"
                sh '''
                docker compose down || true
                docker compose up -d
                '''
            }
        }
    }

    post {
        always {
            echo "📦 Pipeline execution completed"
        }

        success {
            echo "✅ Build & Deployment Successful"
            echo "🌐 App        : http://<EC2-IP>:8080"
            echo "🔍 SonarQube  : http://<EC2-IP>:9000"
            echo "📊 Prometheus : http://<EC2-IP>:9090"
            echo "📈 Grafana    : http://<EC2-IP>:3000"
        }

        failure {
            echo "❌ Pipeline Failed – Check Jenkins logs"
        }
    }
}
