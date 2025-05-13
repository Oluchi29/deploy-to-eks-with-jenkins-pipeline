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
                dir('terraform-new') {
                    sh 'terraform init'
                }
            }
        }

        stage("Terraform Format") {
            steps {
                dir('terraform-new') {
                    sh 'terraform fmt'
                }
            }
        }

        stage("Terraform Validate") {
            steps {
                dir('terraform-new') {
                    sh 'terraform validate'
                }
            }
        }

        stage("Terraform Plan") {
            when {
                expression { return params.action == 'apply' }
            }
            steps {
                dir('terraform-new') {
                    sh 'terraform plan'
                }
            }
        }

        stage("Delete Kubernetes Workloads") {
            when {
                expression { return params.action == 'destroy' }
            }
            steps {
                dir('kubernetes') {
                    script {
                        sh "aws eks update-kubeconfig --region us-east-1 --name my-eks-cluster-200 || true"
                        sh "kubectl delete -f nginx-service.yaml || true"
                        sh "kubectl delete -f nginx-deployment.yaml || true"
                    }
                }
            }
        }

stage("Force Cleanup AWS Resources") {
    when {
        expression { return params.action == 'destroy' }
    }
    steps {
        script {
            sh '''
            echo "Updating kubeconfig..."
            aws eks update-kubeconfig --region us-east-1 --name my-eks-cluster-200 || true

            echo "Deleting Kubernetes resources..."
            kubectl delete -f kubernetes/nginx-service.yaml --ignore-not-found
            kubectl delete -f kubernetes/nginx-deployment.yaml --ignore-not-found

            echo "Deleting services of type LoadBalancer..."
            kubectl delete svc --all --ignore-not-found
            kubectl delete ingress --all --ignore-not-found

            echo "Deleting all node groups (if managed outside Terraform)..."
            aws eks list-nodegroups --cluster-name my-eks-cluster-200 --query 'nodegroups' --output text | tr '\t' '\n' | while read nodegroup; do
                aws eks delete-nodegroup --cluster-name my-eks-cluster-200 --nodegroup-name "$nodegroup"
            done

            echo "Waiting for node group deletion to propagate..."
            sleep 60

            echo "You can also manually clean ENIs here if necessary using:"
            echo "aws ec2 describe-network-interfaces --filters Name=vpc-id,Values=<your-vpc-id>"
            '''
        }
    }
}

        stage("Terraform Apply or Destroy") {
            steps {
                dir('terraform-new') {
                    echo "Running terraform ${params.action}"
                    sh "terraform ${params.action} --auto-approve"
                }
            }
        }

        stage("Deploy to EKS") {
            when {
                expression { return params.action == 'apply' }
            }
            steps {
                dir('kubernetes') {
                    sh "aws eks update-kubeconfig --region us-east-1 --name my-eks-cluster-200"
                    sh "kubectl config current-context"
                    sh "kubectl get pods"
                    sh "kubectl apply -f nginx-deployment.yaml"
                    sh "kubectl apply -f nginx-service.yaml"
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
