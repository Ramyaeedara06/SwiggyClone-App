pipeline {
  agent any
  environment {
    // Change these to your values
    REGISTRY = "docker.io/yourdockerhubuser"   // e.g., docker.io/myuser or <aws_account_id>.dkr.ecr.us-east-1.amazonaws.com
    IMAGE_NAME = "${REGISTRY}/swiggy-clone"
    DOCKER_CREDENTIALS = "docker-registry-creds"   // Jenkins credential id for registry (username/password)
    KUBECONFIG_CREDENTIALS = "kubeconfig"          // Jenkins file-credential id containing kubeconfig
  }
  options {
    ansiColor('xterm')
    timestamps()
    buildDiscarder(logRotator(numToKeepStr: '10'))
  }
  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Set metadata') {
      steps {
        script {
          COMMIT = sh(script: "git rev-parse --short HEAD", returnStdout: true).trim()
          BR = env.BRANCH_NAME ?: 'local'
          IMAGE_TAG = "${BR}-${COMMIT}"
          echo "TAG -> ${IMAGE_TAG}"
        }
      }
    }

    stage('Install & Lint') {
      steps {
        sh 'npm ci'
        sh 'npm run lint || true'
      }
    }

    stage('Unit tests') {
      steps {
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

    stage('Deploy to Kubernetes') {
      steps {
        withCredentials([file(credentialsId: KUBECONFIG_CREDENTIALS, variable: 'KUBECONFIG_FILE')]) {
          sh '''
            mkdir -p $HOME/.kube
            cp $KUBECONFIG_FILE $HOME/.kube/config
            # Replace the placeholder image name in k8s/deployment.yaml and apply
            sed -i "s|REPLACE_IMAGE|${IMAGE_NAME}:${IMAGE_TAG}|" k8s/deployment.yaml || true
            kubectl apply -f k8s/namespace.yaml || true
            kubectl apply -f k8s/
            kubectl rollout status deployment/swiggy-deployment -n swiggy --timeout=120s || true
          '''
        }
      }
    }
  }
  post {
    success {
      echo "Pipeline completed: ${IMAGE_NAME}:${IMAGE_TAG}"
    }
    failure {
      echo "Pipeline failed."
    }
    always {
      cleanWs()
    }
  }
}
