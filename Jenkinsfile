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
          kubectl create namespace swiggy --dry-run=client -o yaml | kubectl apply -f -
          if ! kubectl -n swiggy get deployment swiggy-deployment > /dev/null 2>&1; then
              echo "Deployment not found, creating deployment..."
              kubectl -n swiggy apply -f k8s/deployment.yaml
          fi
          kubectl -n swiggy set image deployment/swiggy-deployment swiggy=${IMAGE_NAME}:${IMAGE_TAG}
          kubectl -n swiggy rollout status deployment/swiggy-deployment --timeout=120s
        """
      }
    }
    stage('Smoke Test') {
      steps {
        sh """
          echo "Waiting for pods to be ready..."
          kubectl -n swiggy wait --for=condition=ready pod -l app=swiggy --timeout=60s
          kubectl -n swiggy port-forward svc/swiggy-svc 30001:80 &
          sleep 5
          curl --fail --max-time 10 http://127.0.0.1:30001 || (echo 'Smoke test failed' && exit 1)
        """
      }
    }
  }    
post {
    success { echo 'Deployment succeeded ✅' }
    failure { echo 'Deployment failed — check logs & kubectl describe pods ❌' }
  }
}
