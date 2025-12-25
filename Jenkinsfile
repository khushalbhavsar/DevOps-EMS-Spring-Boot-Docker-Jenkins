pipeline {
    // Agent Configuration
    // Option 1: Use 'any' available agent (default)
    // Option 2: Use master/built-in node
    // Option 3: Use specific label (requires Jenkins node setup)
    agent any
    // agent { label 'dev-server' }  // Uncomment if you have 'dev-server' label configured

    options {
        buildDiscarder(logRotator(numToKeepStr: '10'))
        timeout(time: 1, unit: 'HOURS')
        timestamps()
    }

    tools {
        maven 'myMaven'
    }

    environment {
        SONAR_TOKEN = credentials('sonar-token')
        SONAR_HOST_URL = "${SONAR_HOST_URL ?: 'http://localhost:9000'}"
        IMAGE_NAME = "employee-management"
        DOCKER_TAG = "${BUILD_NUMBER}"
        REGISTRY = "${REGISTRY ?: 'docker.io'}"
        BUILD_ARTIFACTS = "target/employee-management-*.jar"
    }

    stages {

        stage('Checkout Source') {
            steps {
                timeout(time: 10, unit: 'MINUTES') {
                    echo "📥 Checking out source code"
                    checkout scm
                }
            }
        }

        stage('Maven Build') {
            steps {
                timeout(time: 20, unit: 'MINUTES') {
                    echo "🔨 Building Java Application"
                    sh 'mvn clean package -DskipTests'
                }
            }
        }

        stage('Unit Tests') {
            steps {
                timeout(time: 15, unit: 'MINUTES') {
                    echo "🧪 Running Unit Tests"
                    sh 'mvn test'
                }
            }
        }

        stage('SonarQube Analysis') {
            steps {
                timeout(time: 15, unit: 'MINUTES') {
                    echo "🔍 Running SonarQube Analysis"
                    sh """
                        mvn sonar:sonar \
                          -Dsonar.projectKey=employee-management \
                          -Dsonar.host.url=${SONAR_HOST_URL} \
                          -Dsonar.login=${SONAR_TOKEN}
                    """
                }
            }
        }

        stage('Archive Artifacts') {
            steps {
                timeout(time: 5, unit: 'MINUTES') {
                    echo "📦 Archiving Build Artifacts"
                    archiveArtifacts artifacts: "${BUILD_ARTIFACTS}",
                                     allowEmptyArchive: true,
                                     fingerprint: true
                }
            }
        }

        stage('Docker Build') {
            steps {
                timeout(time: 15, unit: 'MINUTES') {
                    echo "🐳 Building Docker Image"
                    sh """
                        docker build -t ${IMAGE_NAME}:${DOCKER_TAG} .
                        docker tag ${IMAGE_NAME}:${DOCKER_TAG} ${IMAGE_NAME}:latest
                    """
                }
            }
        }

        stage('Push Image to Registry') {
            steps {
                timeout(time: 15, unit: 'MINUTES') {
                    echo "📤 Pushing Docker Image to Registry"
                    withCredentials([usernamePassword(
                        credentialsId: 'dockerHubCreds',
                        usernameVariable: 'DOCKER_USER',
                        passwordVariable: 'DOCKER_PASS'
                    )]) {
                        sh """
                            echo "${DOCKER_PASS}" | docker login -u "${DOCKER_USER}" --password-stdin ${REGISTRY}

                            docker tag ${IMAGE_NAME}:${DOCKER_TAG} ${DOCKER_USER}/${IMAGE_NAME}:${DOCKER_TAG}
                            docker tag ${IMAGE_NAME}:${DOCKER_TAG} ${DOCKER_USER}/${IMAGE_NAME}:latest

                            docker push ${DOCKER_USER}/${IMAGE_NAME}:${DOCKER_TAG}
                            docker push ${DOCKER_USER}/${IMAGE_NAME}:latest

                            docker logout ${REGISTRY}
                        """
                    }
                }
            }
        }

        stage('Deploy Application') {
            steps {
                timeout(time: 10, unit: 'MINUTES') {
                    echo "🚀 Deploying Application"
                    sh '''
                        docker compose down || true
                        docker compose up -d
                    '''
                }
            }
        }

        stage('Cleanup') {
            steps {
                timeout(time: 5, unit: 'MINUTES') {
                    echo "🧹 Cleaning up Docker resources"
                    sh '''
                        docker image prune -af --filter "until=72h" || true
                        docker container prune -f --filter "until=72h" || true
                    '''
                }
            }
        }
    }

    post {
        always {
            echo "📦 Pipeline completed at ${new Date().format('yyyy-MM-dd HH:mm:ss')}"
            cleanWs()
        }

        success {
            echo "✅ Build & Deployment Successful!"
        }

        failure {
            echo "❌ Pipeline Failed!"
            echo "🔗 Logs: ${BUILD_URL}console"
        }

        unstable {
            echo "⚠️ Pipeline unstable"
        }
    }
}
