pipeline {
    agent any
    
    environment {
        DOCKER_REGISTRY = "<ECR registry-url>"
        DOCKER_IMAGE = "<image-name>"
        DOCKER_TAG = "${BUILD_NUMBER}"
        KUBECONFIG = credentials('eks-kubeconfig')
        SONAR_TOKEN = credentials('sonar-token')
        SNYK_TOKEN = credentials('snyk-token')
        AWS_CREDENTIALS = credentials('aws-credentials')
        GIT_CREDENTIALS = credentials('git-credentials')
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        
        stage('Credential Scan') {
            steps {
                script {
                    // Install Gitleaks if not already installed
                    sh '''
                        if ! command -v gitleaks &> /dev/null; then
                            wget https://github.com/zricethezav/gitleaks/releases/latest/download/gitleaks-linux-amd64 -O gitleaks
                            chmod +x gitleaks
                            sudo mv gitleaks /usr/local/bin/
                        fi
                    '''
                    
                    // Run Gitleaks
                    sh '''
                        gitleaks detect --source . --verbose --report-path gitleaks-report.json
                        if [ $? -eq 1 ]; then
                            echo "Secrets found in code. Check gitleaks-report.json"
                            exit 1
                        fi
                    '''
                }
            }
        }

        stage('SonarQube Analysis') {
            steps {
                script {
                    def scannerHome = tool 'SonarScanner'
                    withSonarQubeEnv('SonarQube') {
                        sh """
                            ${scannerHome}/bin/sonar-scanner \
                            -Dsonar.projectKey=<project-key> \
                            -Dsonar.sources=. \
                            -Dsonar.host.url=<sonarqube-url> \
                            -Dsonar.login=${SONAR_TOKEN}
                        """
                    }
                    
                    // Wait for quality gate
                    timeout(time: 5, unit: 'MINUTES') {
                        def qg = waitForQualityGate()
                        if (qg.status != 'OK') {
                            error "Pipeline aborted due to quality gate failure: ${qg.status}"
                        }
                    }
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    docker.build("${DOCKER_REGISTRY}/${DOCKER_IMAGE}:${DOCKER_TAG}")
                }
            }
        }

        stage('Snyk Container Scan') {
            steps {
                script {
                    // Install Snyk CLI if not already installed
                    sh '''
                        if ! command -v snyk &> /dev/null; then
                            npm install -g snyk
                        fi
                    '''
                    
                    // Authenticate with Snyk
                    withCredentials([string(credentialsId: 'snyk-token', variable: 'SNYK_TOKEN')]) {
                        sh 'snyk auth ${SNYK_TOKEN}'
                    }
                    
                    // Scan Docker image
                    sh """
                        snyk container test ${DOCKER_REGISTRY}/${DOCKER_IMAGE}:${DOCKER_TAG} \
                        --severity-threshold=high \
                        --file=Dockerfile
                    """
                }
            }
        }

        stage('Push Docker Image') {
            steps {
                script {
                    docker.withRegistry("https://${DOCKER_REGISTRY}", 'docker-credentials') {
                        docker.image("${DOCKER_REGISTRY}/${DOCKER_IMAGE}:${DOCKER_TAG}").push()
                    }
                }
            }
        }

        stage('Deploy to EKS') {
            steps {
                script {
                    // Configure AWS credentials
                    withAWS(credentials: 'aws-credentials', region: 'ap-southeast-1') {
                        // Update kubeconfig
                        sh "aws eks update-kubeconfig --name <cluster-name> --region ap-southeast-1"
                        
                        // Apply Kubernetes manifests
                        sh """
                            # Update image tag in deployment.yaml
                            sed -i 's|image: ${DOCKER_REGISTRY}/${DOCKER_IMAGE}:.*|image: ${DOCKER_REGISTRY}/${DOCKER_IMAGE}:${DOCKER_TAG}|' k8s/deployment.yaml
                            
                            # Apply manifests
                            kubectl apply -f k8s/
                            
                            # Wait for deployment to complete
                            kubectl rollout status deployment/<deployment-name> -n <namespace>
                        """
                    }
                }
            }
        }
    }

    post {
        always {
            // Clean workspace
            cleanWs()
            
            // Send notification
            script {
                if (currentBuild.result == 'FAILURE') {
                    // Send failure notification
                    emailext (
                        subject: "Pipeline Failed: ${currentBuild.fullDisplayName}",
                        body: "Pipeline failed at stage: ${currentBuild.description}",
                        recipientProviders: [[$class: 'DevelopersRecipientProvider']]
                    )
                }
            }
        }
        success {
            // Archive artifacts and reports
            archiveArtifacts artifacts: 'gitleaks-report.json, k8s/*.yaml', allowEmptyArchive: true
        }
    }
}
