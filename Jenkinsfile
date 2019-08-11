pipeline {
  agent any
  stages {
    stage ("Build") {
      agent {
        docker {
           label 'dockerserver'
           image 'maven:3.6.0-jdk-8-alpine'
           args '-v /root/.m2/repository:/root/.m2/repository'
        }
      }
      steps {
              sh 'mvn clean package'
              sh "docker build . -t tomcatwebappserver:${env.BUILD_ID}"

      }
    }
  }
}
