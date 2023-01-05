pipeline {
    agent any
    tools{
        terraform "terraform"
        maven "maven"
       
    }
    parameters {
        choice(
            name: 'Infrastructure',
            choices: ['create', 'destroy'],
            description: ''
        )
    }
    environment {
        AWS_ACCESS_KEY_ID     = credentials('AWS_ACCESS_KEY_ID')
        AWS_SECRET_ACCESS_KEY = credentials('AWS_SECRET_ACCESS_KEY')
    }
    stages {
        stage('git clone') {
            steps {
              git branch: 'terraform', url: "https://github.com/sainath028/suresh.git" 
              sh "ls -ll"
            }
        }
        stage ('Build') {
            steps {
                sh "mvn clean install -DskipTests"
            }
        }
        
        stage('terraform init') {
            steps {
              sh "terraform init" 
            }
        }
        
        stage('terraform plan') {
            steps {
                script {
                    sh  "ls -ll"
                    sh "terraform plan"
                }
            }
        }
        
        stage('terraform apply') {
            steps {
                script {
                    if (env.Infrastructure == 'create') {
                        sh "terraform apply -no-color --auto-approve"
                    } else {
                        sh "terraform destroy -no-color --auto-approve"
                    }
                }  
            }
        }
        stage ('deployment') {
            steps {
                script {
                    if (env.Infrastructure == 'create') {
                        sh "chmod 400 jenkins.pem"
                        sh "ansible-playbook copy.yaml"
                    } else {
                        echo 'destroyed'
                    }
                }  
            }
        }                
    }
}
