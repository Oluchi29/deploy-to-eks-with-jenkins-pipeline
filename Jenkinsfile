pipeline {
    agent any

    environment {
        AWS_ACCESS_KEY_ID = credentials('AWS_ACCESS_KEY_ID')
        AWS_SECRET_ACCESS_KEY = credentials('AWS_SECRET_ACCESS_KEY')
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
                dir('terraform') {
                    script {
                        withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-eks-creds']]) {
                            sh 'terraform init'
                            sh 'terraform fmt'
                            sh 'terraform validate'
                        }
                    }
                }
            }
        }

        stage("Terraform Apply or Destroy") {
            steps {
                dir('terraform') {
                    script {
                        echo "Running terraform ${params.action}"
                        withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-eks-creds']]) {
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
                            sh "aws eks update-kubeconfig --region us-east-1 --name my-eks-cluster-200"
                            sh "kubectl config current-context"
                            sh "kubectl get pods"
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
