// pipeline {

//     agent any

//     options {
//         buildDiscarder(logRotator(numToKeepStr: '10'))
//         timeout(time: 3, unit: 'HOURS')   // ⬅ increased (important)
//         timestamps()
//     }

//     tools {
//         maven 'myMaven'
//     }

//     environment {
//         // SonarQube
//         SONAR_TOKEN = credentials('sonar-token')
//         SONAR_HOST_URL = "${SONAR_HOST_URL ?: 'http://localhost:9000'}"

//         // Docker
//         IMAGE_NAME = "employee-management"
//         DOCKER_TAG = "${BUILD_NUMBER}"
//         REGISTRY = "${REGISTRY ?: 'docker.io'}"

//         // Artifacts
//         BUILD_ARTIFACTS = "target/employee-management-*.jar"

//         // Maven cache (VERY IMPORTANT)
//         MAVEN_OPTS = "-Dmaven.repo.local=/var/lib/jenkins/.m2/repository"
//     }

//     stages {

//         stage('Checkout Source') {
//             steps {
//                 timeout(time: 10, unit: 'MINUTES') {
//                     echo "========================================"
//                     echo "📥 STAGE: Checkout Source"
//                     echo "========================================"
//                     echo "🔄 Fetching source code from repository..."
//                     checkout scm
//                     echo "✅ Source code checkout completed successfully"
//                 }
//             }
//         }

//         stage('Maven Build') {
//             steps {
//                 timeout(time: 60, unit: 'MINUTES') {
//                     echo "========================================"
//                     echo "🔨 STAGE: Maven Build"
//                     echo "========================================"
//                     echo "🔄 Cleaning previous build artifacts..."
//                     echo "🔄 Compiling Java source code..."
//                     echo "🔄 Packaging application (skipping tests)..."
//                     sh 'mvn clean package -DskipTests'
//                     echo "✅ Maven build completed successfully"
//                 }
//             }
//         }

//         stage('Unit Tests') {
//             steps {
//                 timeout(time: 30, unit: 'MINUTES') {
//                     echo "========================================"
//                     echo "🧪 STAGE: Unit Tests"
//                     echo "========================================"
//                     echo "🔄 Executing unit test suite..."
//                     sh 'mvn test'
//                     echo "✅ All unit tests passed successfully"
//                 }
//             }
//         }

//         stage('SonarQube Analysis') {
//             steps {
//                 timeout(time: 30, unit: 'MINUTES') {
//                     echo "========================================"
//                     echo "🔍 STAGE: SonarQube Analysis"
//                     echo "========================================"
//                     echo "🔄 Connecting to SonarQube server..."
//                     echo "🔄 Analyzing code quality and security..."
//                     script {
//                         try {
//                             withCredentials([string(credentialsId: 'sonar-token', variable: 'SONAR_TOKEN_SECRET')]) {
//                                 sh '''
//                                     mvn sonar:sonar \
//                                       -Dsonar.projectKey=employee-management \
//                                       -Dsonar.host.url=$SONAR_HOST_URL \
//                                       -Dsonar.login=$SONAR_TOKEN_SECRET
//                                 '''
//                             }
//                             echo "✅ SonarQube analysis completed successfully"
//                         } catch (err) {
//                             echo "⚠️ SonarQube analysis failed, continuing pipeline..."
//                             echo "⚠️ Error: ${err.getMessage()}"
//                         }
//                     }
//                 }
//             }
//         }

//         stage('Archive Artifacts') {
//             steps {
//                 timeout(time: 10, unit: 'MINUTES') {
//                     echo "========================================"
//                     echo "📦 STAGE: Archive Artifacts"
//                     echo "========================================"
//                     echo "🔄 Collecting build artifacts..."
//                     echo "🔄 Archiving JAR files from target directory..."
//                     archiveArtifacts artifacts: "${BUILD_ARTIFACTS}",
//                                      allowEmptyArchive: true,
//                                      fingerprint: true
//                     echo "✅ Build artifacts archived successfully"
//                 }
//             }
//         }

//         stage('Docker Build') {
//             steps {
//                 timeout(time: 30, unit: 'MINUTES') {
//                     echo "========================================"
//                     echo "🐳 STAGE: Docker Build"
//                     echo "========================================"
//                     echo "🔄 Checking Docker installation..."
//                     echo "🔄 Building Docker image from Dockerfile..."
//                     echo "🔄 Tagging image with build number: ${DOCKER_TAG}"
//                     sh '''
//                         docker --version
//                         docker build -t ${IMAGE_NAME}:${DOCKER_TAG} .
//                         docker tag ${IMAGE_NAME}:${DOCKER_TAG} ${IMAGE_NAME}:latest
//                     '''
//                     echo "✅ Docker image built and tagged successfully"
//                 }
//             }
//         }

//         stage('Push Image to Registry') {
//             steps {
//                 timeout(time: 30, unit: 'MINUTES') {
//                     echo "========================================"
//                     echo "📤 STAGE: Push Image to Registry"
//                     echo "========================================"
//                     echo "🔄 Authenticating with Docker Hub..."
//                     withCredentials([usernamePassword(
//                         credentialsId: 'dockerHubCreds',
//                         usernameVariable: 'DOCKER_USER',
//                         passwordVariable: 'DOCKER_PASS'
//                     )]) {
//                         sh '''
//                             echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
//                             echo "🔄 Tagging images for Docker Hub..."
//                             docker tag ${IMAGE_NAME}:${DOCKER_TAG} $DOCKER_USER/${IMAGE_NAME}:${DOCKER_TAG}
//                             docker tag ${IMAGE_NAME}:${DOCKER_TAG} $DOCKER_USER/${IMAGE_NAME}:latest
//                             echo "🔄 Pushing image with tag: ${DOCKER_TAG}..."
//                             docker push $DOCKER_USER/${IMAGE_NAME}:${DOCKER_TAG}
//                             echo "🔄 Pushing image with tag: latest..."
//                             docker push $DOCKER_USER/${IMAGE_NAME}:latest
//                             docker logout
//                         '''
//                     }
//                     echo "✅ Docker images pushed to registry successfully"
//                 }
//             }
//         }

//         stage('Deploy Application') {
//             steps {
//                 timeout(time: 15, unit: 'MINUTES') {
//                     echo "========================================"
//                     echo "🚀 STAGE: Deploy Application"
//                     echo "========================================"
//                     echo "🔄 Stopping ALL existing containers on required ports..."
//                     sh '''
//                         # Stop any container using port 9000 (SonarQube)
//                         docker ps -q --filter "publish=9000" | xargs -r docker stop || true
//                         docker ps -aq --filter "publish=9000" | xargs -r docker rm -f || true
                        
//                         # Stop any container using port 8081 (App - Jenkins uses 8080)
//                         docker ps -q --filter "publish=8081" | xargs -r docker stop || true
//                         docker ps -aq --filter "publish=8081" | xargs -r docker rm -f || true
                        
//                         # Stop any container using port 9090 (Prometheus)
//                         docker ps -q --filter "publish=9090" | xargs -r docker stop || true
//                         docker ps -aq --filter "publish=9090" | xargs -r docker rm -f || true
                        
//                         # Stop any container using port 3000 (Grafana)
//                         docker ps -q --filter "publish=3000" | xargs -r docker stop || true
//                         docker ps -aq --filter "publish=3000" | xargs -r docker rm -f || true
                        
//                         # Also stop any existing ems_java containers
//                         docker ps -aq --filter "name=ems_java" | xargs -r docker rm -f || true
//                     '''
//                     echo "🔄 Stopping existing docker-compose services..."
//                     sh 'docker compose down --remove-orphans || true'
//                     echo "🔄 Starting new containers with docker-compose..."
//                     sh '''
//                         docker compose up -d
//                         echo "🔄 Verifying container status..."
//                         sleep 5
//                         docker compose ps
//                     '''
//                     echo "✅ Application deployed successfully"
//                 }
//             }
//         }

//         stage('Cleanup') {
//             steps {
//                 timeout(time: 10, unit: 'MINUTES') {
//                     echo "========================================"
//                     echo "🧹 STAGE: Cleanup"
//                     echo "========================================"
//                     echo "🔄 Removing dangling Docker images..."
//                     echo "🔄 Removing stopped containers..."
//                     sh '''
//                         docker image prune -af || true
//                         docker container prune -f || true
//                     '''
//                     echo "✅ Docker cleanup completed successfully"
//                 }
//             }
//         }
//     }

//     post {
//         always {
//             echo "========================================"
//             echo "📋 PIPELINE SUMMARY"
//             echo "========================================"
//             echo "📦 Pipeline completed at ${new Date().format('yyyy-MM-dd HH:mm:ss')}"
//             echo "🔢 Build Number: ${BUILD_NUMBER}"
//             echo "🌿 Branch: ${env.GIT_BRANCH ?: 'N/A'}"
//             echo "🔄 Cleaning workspace..."
//             cleanWs()
//             echo "✅ Workspace cleaned"
//         }

//         success {
//             echo "========================================"
//             echo "✅ SUCCESS: Build & Deployment Completed!"
//             echo "========================================"
//             echo "🐳 Docker Image: ${IMAGE_NAME}:${DOCKER_TAG}"
//             echo "🔗 Build URL: ${BUILD_URL}"
//         }

//         failure {
//             echo "========================================"
//             echo "❌ FAILURE: Pipeline Failed!"
//             echo "========================================"
//             echo "🔗 Check Console Logs: ${BUILD_URL}console"
//             echo "📧 Please review the error and fix the issue"
//         }

//         unstable {
//             echo "========================================"
//             echo "⚠️ UNSTABLE: Pipeline completed with warnings"
//             echo "========================================"
//             echo "🔍 Some tests may have failed or quality gates not met"
//         }
//     }
// }





pipeline {

    agent any

    options {
        buildDiscarder(logRotator(numToKeepStr: '10'))
        timeout(time: 3, unit: 'HOURS')
        timestamps()
    }

    tools {
        maven 'myMaven'
    }

    environment {
        // SonarQube (EXTERNAL EC2)
        SONAR_TOKEN = credentials('sonar-token')
        SONAR_HOST_URL = "http://44.201.111.248:9000"

        // Docker
        IMAGE_NAME = "employee-management"
        DOCKER_TAG = "${BUILD_NUMBER}"

        // Artifacts
        BUILD_ARTIFACTS = "target/employee-management-*.jar"

        // Maven cache
        MAVEN_OPTS = "-Dmaven.repo.local=/var/lib/jenkins/.m2/repository"
    }

    stages {

        stage('Checkout Source') {
            steps {
                timeout(time: 10, unit: 'MINUTES') {
                    echo "📥 STAGE: Checkout Source"
                    checkout scm
                }
            }
        }

        stage('Maven Build') {
            steps {
                timeout(time: 60, unit: 'MINUTES') {
                    echo "🔨 STAGE: Maven Build"
                    sh 'mvn clean package -DskipTests'
                }
            }
        }

        stage('Unit Tests') {
            steps {
                timeout(time: 30, unit: 'MINUTES') {
                    echo "🧪 STAGE: Unit Tests"
                    sh 'mvn test'
                }
            }
        }

        stage('SonarQube Analysis') {
            steps {
                timeout(time: 30, unit: 'MINUTES') {
                    echo "🔍 STAGE: SonarQube Analysis"
                    script {
                        try {
                            sh '''
                                mvn sonar:sonar \
                                  -Dsonar.projectKey=employee-management \
                                  -Dsonar.host.url=$SONAR_HOST_URL \
                                  -Dsonar.token=$SONAR_TOKEN
                            '''
                            echo "✅ SonarQube analysis completed"
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
                    echo "📦 STAGE: Archive Artifacts"
                    archiveArtifacts artifacts: "${BUILD_ARTIFACTS}",
                                     allowEmptyArchive: true,
                                     fingerprint: true
                }
            }
        }

        stage('Docker Build') {
            steps {
                timeout(time: 30, unit: 'MINUTES') {
                    echo "🐳 STAGE: Docker Build"
                    sh '''
                        docker build -t ${IMAGE_NAME}:${DOCKER_TAG} .
                        docker tag ${IMAGE_NAME}:${DOCKER_TAG} ${IMAGE_NAME}:latest
                    '''
                }
            }
        }

        stage('Push Image to Registry') {
            steps {
                timeout(time: 30, unit: 'MINUTES') {
                    echo "📤 STAGE: Push Image to Registry"
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
                    echo "🚀 STAGE: Deploy Application"

                    sh '''
                        echo "🔄 Stopping only application-related containers (SAFE)..."
                        docker ps -aq --filter "name=employee-management" | xargs -r docker rm -f || true

                        echo "🔄 Deploying with docker-compose..."
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
                    echo "🧹 STAGE: Cleanup"
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
            echo "📦 Pipeline finished at ${new Date().format('yyyy-MM-dd HH:mm:ss')}"
            cleanWs()
        }

        success {
            echo "✅ SUCCESS: Build & Deployment Completed!"
            echo "🐳 Docker Image: ${IMAGE_NAME}:${DOCKER_TAG}"
        }

        failure {
            echo "❌ FAILURE: Pipeline Failed!"
            echo "🔗 Logs: ${BUILD_URL}console"
        }
    }
}

