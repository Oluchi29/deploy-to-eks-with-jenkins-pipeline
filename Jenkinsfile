

pipeline {
    agent any

    environment {
        AWS_DEFAULT_REGION = "us-east-1"
    }

    parameters {
        choice(
            name: 'action',
            choices: ['apply', 'destroy'],
            description: 'Choose your Terraform action'
        )
    }

    stages {
        stage("Terraform Init") {
            steps {
                dir('terraform1') {
                    sh 'terraform init'
                    sh 'terraform fmt'
                    sh 'terraform validate'
                }
            }
        }

        stage("Terraform ${params.action.capitalize()} EKS Cluster") {
            steps {
                dir('terraform1') {
                    script {
                        withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-eks-creds']]) {
                            echo "You are about to run terraform ${params.action} to manage the EKS cluster"
                            sh "terraform ${params.action} --auto-approve"
                        }
                    }
                }
            }
        }

        stage("Deploy to EKS") {
            when {
                expression { return params.action == 'apply' }
            }
            steps {
                dir('kubernetes') {
                    script {
                        withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-eks-creds']]) {
                            sh "aws eks update-kubeconfig --region us-east-1 --name my-eks-cluster-209"
                            sh "kubectl config current-context"
                            sh "kubectl get ns"
                            sh "kubectl apply -f nginx-deployment.yaml"
                            sh "kubectl apply -f nginx-service.yaml"
                        }
                    }
                }
            }
        }
    }

    post {
        success {
            echo "✅ Terraform ${params.action} and EKS deployment completed successfully."
        }
        failure {
            echo "❌ Pipeline failed during ${params.action}. Please review the logs."
        }
    }
}
