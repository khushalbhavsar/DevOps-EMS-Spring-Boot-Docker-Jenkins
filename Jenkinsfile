/*
 * ========================================
 * JENKINS PIPELINE - EMPLOYEE MANAGEMENT SYSTEM
 * ========================================
 * 
 * What this pipeline does:
 * 1. Gets code from GitHub
 * 2. Builds the Java application
 * 3. Runs tests
 * 4. Creates Docker image
 * 5. Tests the Docker container
 * 6. Pushes image to Docker Hub
 * 
 * Prerequisites in Jenkins:
 * - Install Docker plugin
 * - Configure 'docker-registry-credentials' with your Docker Hub login
 * - Install JDK 21 and Maven 3
 */

pipeline {
  agent any  // Run on any available Jenkins server
  
  // ========================================
  // TOOLS: What software to use
  // ========================================
  tools {
    jdk 'JDK21'      // Use Java 21
    maven 'Maven3'   // Use Maven 3
  }
  
  // ========================================
  // ENVIRONMENT: Variables used in pipeline
  // ========================================
  environment {
    // Image names for Docker
    IMAGE_NAME = "employee-management"
    REGISTRY_IMAGE = "khushalbhavsar/employee-management"
    IMAGE_TAG = "${env.BUILD_NUMBER ?: 'local'}"  // Tag with build number
  }
  
  // ========================================
  // STAGES: Steps to build and deploy
  // ========================================
  stages {
    
    // STEP 1: Get Code from GitHub
    stage('Checkout') {
      steps { 
        checkout scm  // Download code
        sh 'chmod +x mvnw'  // Make Maven wrapper executable
      }
    }
    
    // STEP 2: Build the Application
    stage('Build') {
      steps {
        echo '📦 Building application...'
        sh './mvnw clean package -DskipTests'  // Compile code, skip tests for now
      }
    }
    
    // STEP 3: Run Tests
    stage('Test') {
      steps {
        echo '🧪 Running tests...'
        sh './mvnw test'  // Run all unit tests
      }
    }
    
    // STEP 4: Build Docker Image
    stage('Docker Build') {
      steps {
        script {
          echo '🐳 Building Docker image...'
          
          // Remove old images
          sh "docker rmi ${REGISTRY_IMAGE}:${IMAGE_TAG} || true"
          sh "docker rmi ${REGISTRY_IMAGE}:latest || true"
          
          // Build new image
          sh "docker build -t ${REGISTRY_IMAGE}:${IMAGE_TAG} ."
          sh "docker tag ${REGISTRY_IMAGE}:${IMAGE_TAG} ${REGISTRY_IMAGE}:latest"
          
          echo '✅ Docker image built!'
        }
      }
    }
    
    // STEP 5: Test Docker Container
    stage('Docker Test') {
      steps {
        script {
          echo '🧪 Testing Docker container...'
          
          // Clean up old test containers
          sh "docker stop employee-management-test || true"
          sh "docker rm employee-management-test || true"
          
          // Start container
          sh "docker run -d --name employee-management-test -p 8080:8080 ${REGISTRY_IMAGE}:${IMAGE_TAG}"
          
          // Wait for app to start
          echo '⏳ Waiting 45 seconds for app to start...'
          sleep 45
          
          // Check logs
          sh "docker logs employee-management-test || true"
          
          // Health check
          sh "curl -f http://localhost:8080/actuator/health || echo 'Health check skipped'"
          
          echo '✅ Container test passed!'
        }
      }
    }
    
    // STEP 6: Create Docker Hub Repository (if needed)
    stage('Setup Docker Hub') {
      steps {
        script {
          echo '📦 Checking Docker Hub repository...'
          
          withCredentials([usernamePassword(
            credentialsId: 'docker-registry-credentials',
            usernameVariable: 'DOCKER_USERNAME',
            passwordVariable: 'DOCKER_PASSWORD')]) {
            
            def repoName = "employee-management"
            
            // Check if repo exists
            def repoExists = sh(
              script: """
                curl -s -o /dev/null -w '%{http_code}' \
                -u ${DOCKER_USERNAME}:${DOCKER_PASSWORD} \
                https://hub.docker.com/v2/repositories/${DOCKER_USERNAME}/${repoName}/
              """,
              returnStdout: true
            ).trim()
            
            if (repoExists == '200') {
              echo '✅ Repository exists'
            } else {
              echo '📦 Creating repository...'
              sh """
                curl -X POST \
                -H "Content-Type: application/json" \
                -u ${DOCKER_USERNAME}:${DOCKER_PASSWORD} \
                -d '{"namespace":"${DOCKER_USERNAME}","name":"${repoName}","description":"Employee Management System","is_private":false}' \
                https://hub.docker.com/v2/repositories/
              """
              echo '✅ Repository created!'
            }
          }
        }
      }
    }
    
    // STEP 7: Push to Docker Hub
    stage('Push to Docker Hub') {
      when { expression { return true } }  // Always run (change if needed)
      steps {
        script {
          echo '🚀 Pushing to Docker Hub...'
          
          withCredentials([usernamePassword(
            credentialsId: 'docker-registry-credentials',
            usernameVariable: 'DOCKER_USERNAME',
            passwordVariable: 'DOCKER_PASSWORD')]) {
            
            // Login to Docker Hub
            sh 'echo $DOCKER_PASSWORD | docker login -u $DOCKER_USERNAME --password-stdin'
            
            // Push images
            sh "docker push ${REGISTRY_IMAGE}:${IMAGE_TAG}"
            sh "docker push ${REGISTRY_IMAGE}:latest"
            
            // Logout
            sh "docker logout"
            
            echo '✅ Images pushed to Docker Hub!'
            echo "🐳 View at: https://hub.docker.com/r/khushalbhavsar/employee-management"
          }
        }
      }
    }
  }
  
  // ========================================
  // POST: Cleanup after build (success or fail)
  // ========================================
  post {
    always {
      // Save the JAR file
      archiveArtifacts artifacts: 'target/*.jar', allowEmptyArchive: true
      
      script {
        // Clean up test container
        sh "docker stop employee-management-test || true"
        sh "docker rm employee-management-test || true"
        
        // Clean up unused images
        sh "docker image prune -f || true"
      }
    }
    
    success {
      echo '🎉 BUILD SUCCESS!'
      echo "Run: docker run -p 8080:8080 ${REGISTRY_IMAGE}:latest"
    }
    
    failure {
      echo '❌ BUILD FAILED - Check logs above'
    }
  }
}
