pipeline {
  agent any
  environment {
    IMAGE_NAME = "your-registry/employee-management"
    IMAGE_TAG  = "${env.BUILD_NUMBER ?: 'local'}"
  }
  stages {
    stage('Checkout') {
      steps { checkout scm }
    }
    stage('Build') {
      steps { sh './mvnw -B -DskipTests clean package' }
    }
    stage('Test') {
      steps { sh './mvnw -B test' }
    }
    stage('Docker Build') {
      steps {
        sh "docker build -t ${IMAGE_NAME}:${IMAGE_TAG} ."
      }
    }
    stage('Docker Push') {
      when { expression { return true } }
      steps {
        script {
          // Login to Docker registry using Jenkins credentials
          withCredentials([usernamePassword(credentialsId: 'docker-registry-credentials', 
                                          usernameVariable: 'DOCKER_USERNAME', 
                                          passwordVariable: 'DOCKER_PASSWORD')]) {
            sh 'echo $DOCKER_PASSWORD | docker login -u $DOCKER_USERNAME --password-stdin'
            sh "docker push ${IMAGE_NAME}:${IMAGE_TAG}"
            sh "docker tag ${IMAGE_NAME}:${IMAGE_TAG} ${IMAGE_NAME}:latest"
            sh "docker push ${IMAGE_NAME}:latest"
          }
        }
      }
    }
  }
  post {
    always { archiveArtifacts artifacts: 'target/*.jar', fingerprint: true }
  }
}