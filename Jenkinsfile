pipeline {
  agent any
  environment {
    SONARQUBE_URL = "http://localhost"
    SONARQUBE_PORT = "9000"
  }
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
      // when {
      //  anyOf { branch 'master'; branch 'develop' }
      // }
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
    stage("Integration tests") {
      agent {
        docker {
          image 'maven:3.6.0-jdk-8-alpine'
          args '-v /root/.m2/repository:/root/.m2/repository'
          reuseNode true
        }
      }
      steps {
       sh 'mvn verify -Dsurefire.skip=true'
      }
      post {
        always {
         junit 'target/failsafe-reports/**/*.xml'
        }
        success {
         stash(name: 'artifact', includes: 'target/*.war')
         stash(name: 'pom', includes: 'pom.xml')
         // to add artifacts in jenkins pipeline tab (UI)
         archiveArtifacts 'target/*.war'
        }
       }
      }
    stage("Code quality analysis") {
      parallel {
        // stage("PMD") {
        //   agent {
        //     docker {
        //       image 'maven:3.6.0-jdk-8-alpine'
        //       args '-v /root/.m2/repository:/root/.m2/repository'
        //       reuseNode true
        //     }
        //   }
        //   steps {
        //     sh 'mvn pmd:pmd'
        //     // using pmd plugin
        //     step([$class: 'PmdPublisher', pattern: '**/target/pmd.xml'])
        //   }
        // }
        // stage("Findbugs") {
        //   agent {
        //     docker {
        //       image 'maven:3.6.0-jdk-8-alpine'
        //       args '-v /root/.m2/repository:/root/.m2/repository'
        //       reuseNode true
        //     }
        //   }
        //   steps {
        //     sh ' mvn findbugs:findbugs'
        //     // using findbugs plugin
        //     findbugs pattern: '**/target/findbugsXml.xml'
        //   }
        // }
        stage("JavaDoc") {
          agent {
            docker {
              image 'maven:3.6.0-jdk-8-alpine'
              args '-v /root/.m2/repository:/root/.m2/repository'
              reuseNode true
            }
          }
          steps {
            sh ' mvn javadoc:javadoc'
            step([$class: 'JavadocArchiver', javadocDir: './target/site/apidocs', keepAll: 'true'])
          }
        }
        stage("SonarQube") {
          agent {
            docker {
              image 'maven:3.6.0-jdk-8-alpine'
              args '-v /root/.m2/repository:/root/.m2/repository'
              reuseNode true
            }
          }
          steps {
            sh " mvn sonar:sonar -Dsonar.host.url=$SONARQUBE_URL:$SONARQUBE_PORT"
          }
        }
      }
      post {
        always {
          // using warning next gen plugin
          recordIssues aggregatingResults: true, tools: [javaDoc(), checkStyle(pattern: '**/target/checkstyle-result.xml')]
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
