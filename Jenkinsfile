#!/usr/bin/env groovy
pipeline {
    agent any
    environment {
        AWS_ACCESS_KEY_ID = credentials('AWS_ACCESS_KEY_ID')
        AWS_SECRET_ACCESS_KEY = credentials('AWS_SECRET_ACCESS_KEY')
        AWS_DEFAULT_REGION = "us-east-1"
    }
     parameters {
        
        
        choice choices: ['apply', 'destroy'], description: '''Choose your terraform action
        ''', name: 'action'
    }
    stages {
         stage("Terraform init stage"){
            steps {
                script {
                    dir('terraform1') {
                       sh'terraform init'
                       sh'terraform fmt'
                       sh'terraform validate'
                    }
                }
            }
        }
        stage("Create an EKS Cluster") {
             when {
                expression {
                    //return params.Appenv
                    return params.action=="apply"
                }
            }
            steps {
                script {
                    dir('terraform1') {
                        echo "You are about to ${params.action} to create the aws eks cluster"
                        
                       
                        sh'terraform ${action} --auto-approve'
                    }
                }
            }
        }
        stage("Destroy the Aws EKS Cluster") {
             when {
                expression {
                    //return params.Appenv
                    return params.action=="destroy"
                }
            }
            steps {
                script {
                    dir('terraform1') {

                        echo "You are about to ${params.action} the aws eks cluster and its resources"
                        
                       
                        sh'terraform ${action} --auto-approve'
                    }
                }
            }
        }
        stage("Deploy to EKS") {
            steps {
                script {
                    dir('kubernetes') {
                        sh "aws eks update-kubeconfig --name my-eks-cluster-209"
                        sh 'kubectl config current-context'
                        sh 'eksctl get cluster'
                        sh "kubectl get ns"
                        sh "kubectl apply -f nginx-deployment.yaml"
                        sh "kubectl apply -f nginx-service.yaml"
                    }
                }
            }
        }
    }
}