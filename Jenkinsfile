pipeline {

    agent any

    options {
        buildDiscarder(logRotator(numToKeepStr: '10'))
        timeout(time: 3, unit: 'HOURS')   // ⬅ increased (important)
        timestamps()
    }

    tools {
        maven 'myMaven'
    }

    environment {
        // SonarQube
        SONAR_TOKEN = credentials('sonar-token')
        SONAR_HOST_URL = "${SONAR_HOST_URL ?: 'http://localhost:9000'}"

        // Docker
        IMAGE_NAME = "employee-management"
        DOCKER_TAG = "${BUILD_NUMBER}"
        REGISTRY = "${REGISTRY ?: 'docker.io'}"

        // Artifacts
        BUILD_ARTIFACTS = "target/employee-management-*.jar"

        // Maven cache (VERY IMPORTANT)
        MAVEN_OPTS = "-Dmaven.repo.local=/var/lib/jenkins/.m2/repository"
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
                timeout(time: 60, unit: 'MINUTES') {
                    echo "🔨 Building Java Application"
                    sh 'mvn clean package -DskipTests'
                }
            }
        }

        stage('Unit Tests') {
            steps {
                timeout(time: 30, unit: 'MINUTES') {
                    echo "🧪 Running Unit Tests"
                    sh 'mvn test'
                }
            }
        }

        stage('SonarQube Analysis') {
            steps {
                timeout(time: 30, unit: 'MINUTES') {
                    echo "🔍 Running SonarQube Analysis"
                    script {
                        try {
                            sh """
                                mvn sonar:sonar \
                                  -Dsonar.projectKey=employee-management \
                                  -Dsonar.host.url=${SONAR_HOST_URL} \
                                  -Dsonar.login=${SONAR_TOKEN}
                            """
                        } catch (err) {
                            echo "⚠️ SonarQube failed, continuing pipeline"
                        }
                    }
                }
            }
        }

        stage('Archive Artifacts') {
            steps {
                timeout(time: 10, unit: 'MINUTES') {
                    echo "📦 Archiving Build Artifacts"
                    archiveArtifacts artifacts: "${BUILD_ARTIFACTS}",
                                     allowEmptyArchive: true,
                                     fingerprint: true
                }
            }
        }

        stage('Docker Build') {
            steps {
                timeout(time: 30, unit: 'MINUTES') {
                    echo "🐳 Building Docker Image"
                    sh '''
                        docker --version
                        docker build -t ${IMAGE_NAME}:${DOCKER_TAG} .
                        docker tag ${IMAGE_NAME}:${DOCKER_TAG} ${IMAGE_NAME}:latest
                    '''
                }
            }
        }

        stage('Push Image to Registry') {
            steps {
                timeout(time: 30, unit: 'MINUTES') {
                    echo "📤 Pushing Docker Image"
                    withCredentials([usernamePassword(
                        credentialsId: 'dockerHubCreds',
                        usernameVariable: 'DOCKER_USER',
                        passwordVariable: 'DOCKER_PASS'
                    )]) {
                        sh '''
                            echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
                            docker tag ${IMAGE_NAME}:${DOCKER_TAG} $DOCKER_USER/${IMAGE_NAME}:${DOCKER_TAG}
                            docker tag ${IMAGE_NAME}:${DOCKER_TAG} $DOCKER_USER/${IMAGE_NAME}:latest
                            docker push $DOCKER_USER/${IMAGE_NAME}:${DOCKER_TAG}
                            docker push $DOCKER_USER/${IMAGE_NAME}:latest
                            docker logout
                        '''
                    }
                }
            }
        }

        stage('Deploy Application') {
            steps {
                timeout(time: 15, unit: 'MINUTES') {
                    echo "🚀 Deploying Application"
                    sh '''
                        docker compose down || true
                        docker compose up -d
                        docker compose ps
                    '''
                }
            }
        }

        stage('Cleanup') {
            steps {
                timeout(time: 10, unit: 'MINUTES') {
                    echo "🧹 Cleaning Docker resources"
                    sh '''
                        docker image prune -af || true
                        docker container prune -f || true
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
