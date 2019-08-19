pipeline {
  agent any
  stages {
    stage("SCM") {
      steps {
        checkout scm
      }
    }
    stage("Build") {
      agent {
        docker {
           image 'maven:3.6.0-jdk-8-alpine'
           args '-v /root/.m2/repository:/root/.m2/repository'
           reuseNode true
        }
      }
      steps {
        sh 'mvn clean package'
      }
    }
    stage("CheckStyle") {
      agent {
        docker {
          image 'maven:3.6.0-jdk-8-alpine'
          args '-v /root/.m2/repository:/root/.m2/repository'
          reuseNode true
        }
      }
      steps {
        sh 'mvn checkstyle:checkstyle'
        step([$class: 'CheckStylePublisher',
         //canRunOnFailed: true,
         defaultEncoding: '',
         healthy: '100',
         pattern: '**/target/checkstyle-result.xml',
         unHealthy: '90',
         //useStableBuildAsReference: true
        ])
      }
    }
    stage("JUnit tests") {
      when {
       anyOf { branch 'master'; branch 'develop' }
      }
      agent {
        docker {
          image 'maven:3.6.0-jdk-8-alpine'
          args '-v /root/.m2/repository:/root/.m2/repository'
          reuseNode true
        }
      }
      steps {
        sh 'mvn test'
      }
      post {
        always {
         junit 'target/surefire-reports/**/*.xml'
        }
      }
    }
	  //  stage ("Build tomcatserver") {
		//   steps {
	  //     sh "docker build . -t tomcatwebappserver:${env.BUILD_ID}"
		//   }
	  // }
  }
}
