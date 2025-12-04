/*
 * Jenkins Pipeline for Employee Management System
 * 
 * This pipeline automates the CI/CD process for a Spring Boot application including:
 * - Source code checkout
 * - Maven build and testing
 * - Docker image creation
 * - Container testing
 * - Docker Hub deployment
 * 
 * Prerequisites:
 * - Jenkins with Docker plugin installed
 * - Docker installed on Jenkins agent
 * - Docker Hub credentials configured in Jenkins as 'docker-registry-credentials'
 */

pipeline {
  // Run this pipeline on any available Jenkins agent
  agent any

  // Global environment variables available to all pipeline stages
  environment {
    IMAGE_NAME = "employee-management"                    // Local Docker image name
    REGISTRY_IMAGE = "khushalbhavsar/employee-management" // Docker Hub repository path
    IMAGE_TAG = "${env.BUILD_NUMBER ?: 'local'}"         // Use Jenkins build number or 'local' as fallback
  }

  // Pipeline stages - executed sequentially
  stages {

    /*
     * STAGE 1: SOURCE CODE CHECKOUT
     * Downloads the latest source code from the configured SCM (Git)
     */
    stage('Checkout') {
      steps { 
        checkout scm  // Checkout source code from version control
        
        // Grant execute permission to Maven wrapper for Linux systems
        sh 'chmod +x mvnw'
      }
    }

    /*
     * STAGE 2: MAVEN BUILD
     * Compiles the Java source code and packages it into a JAR file
     * Skips tests in this stage for faster build (tests run in next stage)
     */
    stage('Build') {
      steps {
        // Use Maven wrapper to ensure consistent build environment
        // -B: Batch mode (non-interactive)
        // -DskipTests: Skip test execution but compile test classes
        sh './mvnw -B -DskipTests clean package'
      }
    }

    /*
     * STAGE 3: UNIT TESTING
     * Executes all unit tests to verify code quality and functionality
     */
    stage('Test') {
      steps {
        // Run all tests using Maven wrapper
        // -B: Batch mode for non-interactive execution
        sh './mvnw -B test'
      }
    }

    /*
     * STAGE 4: DOCKER IMAGE CREATION
     * Builds Docker container image from the compiled JAR file
     * Creates both versioned and latest tags for deployment flexibility
     * RUNS ON: Local machine (requires 'local' label on Jenkins node)
     */
    stage('Docker Build') {
      agent { label 'local' }  // Execute on local machine with 'local' label
      
      steps {
        script {
          echo "Building Docker image on local machine..."
          
          // Clean up any existing images to prevent conflicts
          sh "docker rmi ${REGISTRY_IMAGE}:${IMAGE_TAG} || true"
          sh "docker rmi ${REGISTRY_IMAGE}:latest || true"
          
          // Build new Docker image using Dockerfile in project root
          // Tags with both build-specific version and 'latest'
          sh "docker build -t ${REGISTRY_IMAGE}:${IMAGE_TAG} ."
          sh "docker tag ${REGISTRY_IMAGE}:${IMAGE_TAG} ${REGISTRY_IMAGE}:latest"
          
          // Verify images were created successfully
          sh "docker images | grep ${IMAGE_NAME}"
          
          echo "✅ Docker image built successfully on local machine!"
        }
      }
    }

    /*
     * STAGE 5: CONTAINER INTEGRATION TESTING
     * Runs the Docker container and performs health checks to ensure
     * the application starts correctly and is accessible
     * RUNS ON: Local machine (requires 'local' label on Jenkins node)
     */
    stage('Docker Test Run') {
      agent { label 'local' }  // Execute on local machine with 'local' label
      
      steps {
        script {
          echo "Running container for test on local machine..."

          // Clean up any existing test containers
          sh "docker stop employee-management-test || true"
          sh "docker rm employee-management-test || true"

          // Start container in detached mode for testing
          // Maps port 8080 from container to host port 8080
          sh "docker run -d --name employee-management-test -p 8080:8080 ${REGISTRY_IMAGE}:${IMAGE_TAG}"

          // Wait for Spring Boot application to fully start
          echo "Waiting for application to start..."
          sleep 45

          // Print container logs for debugging if issues occur
          sh "docker logs employee-management-test || true"

          // Perform health check to verify application is running
          // Note: Requires Spring Boot Actuator to be enabled
          sh "curl -f http://localhost:8080/actuator/health || (echo 'Health Check Failed!' && exit 1)"

          echo "Container test passed on local machine!"
        }
      }
    }

    /*
     * STAGE 6: DOCKER HUB DEPLOYMENT
     * Pushes the built Docker images to Docker Hub registry
     * Makes images available for production deployment
     * RUNS ON: Local machine (requires 'local' label on Jenkins node)
     */
    stage('Docker Push') {
      agent { label 'local' }  // Execute on local machine with 'local' label
      
      // Conditional execution - currently always runs (return true)
      // Can be modified to run only on specific branches or conditions
      when { expression { return true } }
      
      steps {
        script {
          echo "🚀 Pushing images to Docker Hub from local machine..."
          
          // Use Jenkins credentials for secure Docker Hub authentication
          withCredentials([usernamePassword(credentialsId: 'docker-registry-credentials',
                                           usernameVariable: 'DOCKER_USERNAME',
                                           passwordVariable: 'DOCKER_PASSWORD')]) {
            
            // Authenticate with Docker Hub
            echo "🔐 Logging in to Docker Hub as ${DOCKER_USERNAME}..."
            sh 'echo $DOCKER_PASSWORD | docker login -u $DOCKER_USERNAME --password-stdin'
            
            // Push versioned image (specific to this build)
            echo "📤 Pushing ${REGISTRY_IMAGE}:${IMAGE_TAG}..."
            sh "docker push ${REGISTRY_IMAGE}:${IMAGE_TAG}"
            
            // Push latest image (overwrites previous 'latest')
            echo "📤 Pushing ${REGISTRY_IMAGE}:latest..."
            sh "docker push ${REGISTRY_IMAGE}:latest"
            
            // Logout for security best practices
            sh "docker logout"
            
            echo "✅ Images pushed successfully to Docker Hub from local machine!"
            echo "🐳 Available at: https://hub.docker.com/r/khushalbhavsar/employee-management"
          }
        }
      }
    }
  }

  /*
   * POST-EXECUTION ACTIONS
   * These actions run after pipeline completion regardless of success/failure
   */
  post {
    // Actions that ALWAYS run after pipeline execution
    always {
      // Archive build artifacts for later reference
      // Saves JAR files with fingerprinting for tracking
      archiveArtifacts artifacts: 'target/*.jar', fingerprint: true, allowEmptyArchive: true

      script {
        // Clean up test containers to free resources
        sh "docker stop employee-management-test || true"
        sh "docker rm employee-management-test || true"
        
        // Clean up dangling Docker images to save disk space
        // -f: Force removal without confirmation
        sh "docker image prune -f || true"
      }
    }

    // Actions that run only on successful pipeline completion
    success {
      echo "🎉 Pipeline completed successfully!"
      echo "Run locally: docker run -p 8080:8080 ${REGISTRY_IMAGE}:latest"
    }
    
    // Actions that run only on pipeline failure
    failure {
      echo "❌ Build failed! Check above logs."
    }
  }
}
