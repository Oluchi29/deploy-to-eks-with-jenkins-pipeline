pipeline {
    agent any

    environment {
        AWS_ACCESS_KEY_ID     = credentials('AWS_ACCESS_KEY_ID')
        AWS_SECRET_ACCESS_KEY = credentials('AWS_SECRET_ACCESS_KEY')
        AWS_DEFAULT_REGION    = 'us-east-1'
        TF_VAR_project_name   = 'eks-terraform-deploy'
        K8S_MANIFEST_PATH     = 'k8s'
        TERRAFORM_DIR         = 'terraform-update'  // <-- Define your Terraform path here
    }

    parameters {
        booleanParam(name: 'CLEANUP', defaultValue: false, description: 'Destroy infrastructure after deployment')
        choice(name: 'WAIT_TIME_MINUTES', choices: ['0', '5', '10', '15', '30'], description: 'Minutes to wait before cleanup')
    }

    stages {
        stage('Checkout Code') {
            steps {
                git branch: 'main', url: 'https://github.com/Oluchi29/deploy-to-eks-with-jenkins-pipeline.git'
            }
        }

        stage('Terraform Init') {
            steps {
                dir("${env.TERRAFORM_DIR}") {
                    sh 'terraform init'
                }
            }
        }

        stage('Terraform Format & Validate') {
            steps {
                dir("${env.TERRAFORM_DIR}") {
                    sh '''
                        terraform fmt
                        terraform fmt -check
                        terraform validate
                    '''
                }
            }
        }

        stage('Terraform Plan') {
            steps {
                dir("${env.TERRAFORM_DIR}") {
                    sh 'terraform plan'
                }
            }
        }

        stage('Terraform Apply - Create EKS') {
            steps {
                dir("${env.TERRAFORM_DIR}") {
                    sh 'terraform apply -auto-approve'
                }
            }
        }

        stage('Set Cluster Name') {
            steps {
                script {
                    def clusterName = sh(
                        script: "terraform -chdir=${env.TERRAFORM_DIR} output -raw cluster_name",
                        returnStdout: true
                    ).trim()
                    env.EKS_CLUSTER_NAME = clusterName
                    echo "EKS Cluster Name: ${clusterName}"
                }
            }
        }

        stage('Configure kubectl') {
            steps {
                sh """
                    aws eks update-kubeconfig \
                        --region ${env.AWS_DEFAULT_REGION} \
                        --name ${env.EKS_CLUSTER_NAME}
                """
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
                expression { return params.CLEANUP && params.WAIT_TIME_MINUTES.toInteger() > 0 }
            }
            steps {
                script {
                    def waitSeconds = params.WAIT_TIME_MINUTES.toInteger() * 60
                    echo " Waiting for ${params.WAIT_TIME_MINUTES} minutes before cleanup..."
                    sleep time: waitSeconds, unit: 'SECONDS'
                }
            }
        }

        stage('Terraform Destroy - Cleanup') {
            when {
                expression { return params.CLEANUP }
            }
            steps {
                dir("${env.TERRAFORM_DIR}") {
                    sh 'terraform destroy -auto-approve'
                }
            }
        }
    }

    post {
        always {
            echo ' Pipeline execution completed.'
        }
        failure {
            echo 'Pipeline failed. Check logs for errors.'
        }
        success {
            echo ' All stages completed successfully.'
        }
    }
}
