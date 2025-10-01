pipeline {
  agent any
  environment {
    IMAGE_NAME = "ramyaeedara015/swiggy-clone" // Docker Hub repo
    DOCKER_CREDENTIALS = "docker-registry-creds" // credential ID you created
    KUBECONFIG_PATH = '/var/lib/jenkins/kube/sa.kubeconfig'
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
    stage('Deploy to k3s') {
      steps {
        sh """
          export KUBECONFIG=${KUBECONFIG_PATH}
          echo "Updating deployment image..."
          kubectl -n swiggy set image deployment/swiggy swiggy=${IMAGE_NAME}:${IMAGE_TAG} --record
          kubectl -n swiggy rollout status deployment/swiggy --timeout=120s
        """
      }
    }
    stage('Smoke Test') {
      steps {
        sh """
          echo "Waiting for pods to be ready..."
          sleep 6
          curl --fail --max-time 10 http://<EC2_PUBLIC_IP>:30001 || (echo 'Smoke test failed' && exit 1)
        """
      }
    }
  }    
post {
    success { echo 'Deployment succeeded ✅' }
    failure { echo 'Deployment failed — check logs & kubectl describe pods ❌' }
  }
}
