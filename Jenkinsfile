pipeline {
  agent any
  environment {
    IMAGE_NAME = "ramyaeedara015/swiggy-clone" // Docker Hub repo
    DOCKER_CREDENTIALS = "docker-registry-creds" // credential ID you created
  }
  options {
    timestamps()
    buildDiscarder(logRotator(numToKeepStr: '10'))
  }
  stages {
    stage('Checkout') {
      steps { checkout scm }
    }
    stage('Set tag') {
      steps {
        script {
          COMMIT = sh(script: "git rev-parse --short HEAD", returnStdout: true).trim()
          BR = env.BRANCH_NAME ?: 'local'
          IMAGE_TAG = "${BR}-${COMMIT}"
          echo "Using image tag: ${IMAGE_TAG}"
        }
      }
    }
    stage('Install & Test') {
      steps {
        sh 'npm ci'
        sh 'npm test'
      }
    }
    stage('Build Docker image') {
      steps {
        sh "docker build -t ${IMAGE_NAME}:${IMAGE_TAG} ."
      }
    }
    stage('Login & Push') {
      steps {
        withCredentials([usernamePassword(credentialsId: DOCKER_CREDENTIALS, usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
          sh 'echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin ${REGISTRY}'
          sh "docker push ${IMAGE_NAME}:${IMAGE_TAG}"
          script {
            if (env.BRANCH_NAME == 'main' || env.BRANCH_NAME == 'master') {
              sh "docker tag ${IMAGE_NAME}:${IMAGE_TAG} ${IMAGE_NAME}:latest"
              sh "docker push ${IMAGE_NAME}:latest"
            }
          }
        }
      }
    }
  }
  post {
    success { echo "Build + push succeeded: ${IMAGE_NAME}:${IMAGE_TAG}" }
    failure { echo "Pipeline failed, check the console output logs" }
    always { cleanWs() }
  }
}

 
