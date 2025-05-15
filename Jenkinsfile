pipeline {
    agent any

    parameters {
        booleanParam(name: 'CLEANUP', defaultValue: false, description: 'Destroy infrastructure after deployment')
        choice(
            name: 'WAIT_MINUTES',
            choices: ['0', '1', '5', '10', '15', '30'],
            description: 'Time to wait (in minutes) before destroying infrastructure'
        )
    }

    environment {
        AWS_ACCESS_KEY_ID = credentials('AWS_ACCESS_KEY_ID')
        AWS_SECRET_ACCESS_KEY = credentials('AWS_SECRET_ACCESS_KEY')
        AWS_DEFAULT_REGION = 'us-east-1'
        TF_VAR_project_name = 'eks-terraform-deploy' // 🔁 Replace with your actual project name
        K8S_MANIFEST_PATH = 'k8s'
    }

    stages {

        stage('Checkout Code') {
            steps {
                git branch: 'main', url: 'https://github.com/Oluchi29/deploy-to-eks-with-jenkins-pipeline.git'
            }
        }

        stage('Terraform Init') {
            steps {
                dir('terraform') {
                    sh 'terraform init'
                }
            }
        }

        stage('Terraform Fmt & Validate') {
            steps {
                dir('terraform') {
                    sh 'terraform fmt -check'
                    sh 'terraform validate'
                }
            }
        }

        stage('Terraform Apply - Create EKS') {
            steps {
                dir('terraform-update') {
                    sh 'terraform apply -auto-approve'
                }
            }
        }

        stage('Configure kubectl') {
            steps {
                script {
                    def clusterName = sh(
                        script: 'terraform -chdir=terraform output -raw cluster_name',
                        returnStdout: true
                    ).trim()

                    env.EKS_CLUSTER_NAME = clusterName

                    sh """
                        aws eks update-kubeconfig \
                            --region $AWS_DEFAULT_REGION \
                            --name ${clusterName}
                    """
                }
            }
        }

        stage('Deploy to EKS') {
            steps {
                sh """
                    kubectl apply -f ${K8S_MANIFEST_PATH}/deployment.yaml
                    kubectl apply -f ${K8S_MANIFEST_PATH}/service.yaml
                """
            }
        }

        stage('Post-Deployment Verification') {
            steps {
                sh 'kubectl get all'
            }
        }

        stage('Wait Before Destroy (Optional)') {
            when {
                expression { return params.CLEANUP && params.WAIT_MINUTES.toInteger() > 0 }
            }
            steps {
                script {
                    def waitTime = params.WAIT_MINUTES.toInteger()
                    echo "⏳ Waiting ${waitTime} minutes before cleanup..."
                    sleep time: waitTime, unit: 'MINUTES'
                }
            }
        }

        stage('Terraform Destroy - Cleanup') {
            when {
                expression { return params.CLEANUP }
            }
            steps {
                dir('terraform') {
                    sh 'terraform destroy -auto-approve'
                }
            }
        }
    }

    post {
        always {
            echo '✅ Pipeline execution completed.'
        }
        failure {
            echo '❌ Pipeline failed. Check logs for errors.'
        }
    }
}
