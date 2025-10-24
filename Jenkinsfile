pipeline {
  agent any
  environment {
    AWS_DEFAULT_REGION = 'us-east-1'
    ECR_REGISTRY = credentials('aws-ecr-registry') // e.g., 123456789012.dkr.ecr.us-east-1.amazonaws.com
    IMAGE_TAG = "${env.BUILD_NUMBER}"
    ECS_CLUSTER = credentials('ecs-cluster-name')
    FRONTEND_SERVICE = credentials('frontend-service-name')
    BACKEND_SERVICE  = credentials('backend-service-name')
    FRONTEND_REPO = "${ECR_REGISTRY}/devops-tech-challenge1-dev-frontend"
    BACKEND_REPO  = "${ECR_REGISTRY}/devops-tech-challenge1-dev-backend"
    REACT_APP_API_URL = "http://backend.local:8080"
    CORS_ALLOWED_ORIGIN = "" // set to "http://<alb-dns>" after terraform apply (as a job param or env)
    FRONTEND_EXEC_ROLE = credentials('frontend-exec-role-arn')
    FRONTEND_TASK_ROLE = credentials('frontend-task-role-arn')
    BACKEND_EXEC_ROLE  = credentials('backend-exec-role-arn')
    BACKEND_TASK_ROLE  = credentials('backend-task-role-arn')
  }
  stages {
    stage('Checkout') { steps { checkout scm } }
    stage('Docker Build') {
      steps {
        sh """
          docker build -t ${FRONTEND_REPO}:${IMAGE_TAG} --build-arg REACT_APP_API_URL=${REACT_APP_API_URL} ./frontend
          docker build -t ${BACKEND_REPO}:${IMAGE_TAG} ./backend
        """
      }
    }
    stage('ECR Login & Push') {
      steps {
        sh """
          aws ecr get-login-password | docker login --username AWS --password-stdin ${ECR_REGISTRY}
          docker push ${FRONTEND_REPO}:${IMAGE_TAG}
          docker push ${BACKEND_REPO}:${IMAGE_TAG}
        """
      }
    }
    stage('Deploy ECS') {
      steps {
        sh """
          chmod +x infra/scripts/update-taskdef.sh

          ECS_CLUSTER=${ECS_CLUSTER} EXEC_ROLE_ARN=${FRONTEND_EXEC_ROLE} TASK_ROLE_ARN=${FRONTEND_TASK_ROLE} \
          PORT=80 ENV_VARS="REACT_APP_API_URL=${REACT_APP_API_URL}" \
          infra/scripts/update-taskdef.sh ${FRONTEND_SERVICE} ${FRONTEND_REPO}:${IMAGE_TAG}

          ECS_CLUSTER=${ECS_CLUSTER} EXEC_ROLE_ARN=${BACKEND_EXEC_ROLE} TASK_ROLE_ARN=${BACKEND_TASK_ROLE} \
          PORT=8080 ENV_VARS="PORT=8080,CORS_ALLOWED_ORIGIN=${CORS_ALLOWED_ORIGIN}" \
          infra/scripts/update-taskdef.sh ${BACKEND_SERVICE} ${BACKEND_REPO}:${IMAGE_TAG}
        """
      }
    }
  }
  post {
    failure { echo "Deployment failed. Check ECS events and CloudWatch logs." }
  }
}
