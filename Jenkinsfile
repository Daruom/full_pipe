pipeline {
  agent any
  environment {

    NEXUS_VERSION = "nexus3"
    // This can be http or https
    NEXUS_PROTOCOL = "http"
    // Where your Nexus is running. In my case:
    NEXUS_URL = "192.168.1.99:9050"
    // Repository where we will upload the artifact
    NEXUS_REPOSITORY = "maven-snapshots"
    // Jenkins credential id to authenticate to Nexus OSS
    NEXUS_CREDENTIAL_ID = "nexus-credentials"

    SONARQUBE_URL = "http://192.168.1.99"
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
    stage('Deploy Artifact To Nexus') {
     steps {
      script {
       unstash 'pom'
       unstash 'artifact'
       // Read POM xml file using 'readMavenPom' step , this step 'readMavenPom' is included in: https://plugins.jenkins.io/pipeline-utility-steps
       pom = readMavenPom file: "pom.xml";
       // Find built artifact under target folder
       filesByGlob = findFiles(glob: "target/*.${pom.packaging}");
       // Print some info from the artifact found
       echo "${filesByGlob[0].name} ${filesByGlob[0].path} ${filesByGlob[0].directory} ${filesByGlob[0].length} ${filesByGlob[0].lastModified}"
       // Extract the path from the File found
       artifactPath = filesByGlob[0].path;
       echo "$(artifactPath)"

       // Assign to a boolean response verifying If the artifact name exists
       artifactExists = fileExists artifactPath;
       if (artifactExists) {
        nexusArtifactUploader(
         nexusVersion: NEXUS_VERSION,
         protocol: NEXUS_PROTOCOL,
         nexusUrl: NEXUS_URL,
         groupId: pom.groupId,
         version: pom.version,
         repository: NEXUS_REPOSITORY,
         credentialsId: NEXUS_CREDENTIAL_ID,
         artifacts: [
          // Artifact generated such as .jar, .ear and .war files.
          [artifactId: pom.artifactId,
           classifier: '',
           file: artifactPath,
           type: pom.packaging
          ],
          // Lets upload the pom.xml file for additional information for Transitive dependencies
          [artifactId: pom.artifactId,
           classifier: '',
           file: "pom.xml",
           type: "pom"
          ]
         ]
        )
       } else {
        error "*** File: ${artifactPath}, could not be found";
       }
      }
     }
    }
    stage('Deploy to Staging Servers') {
     agent {
      docker {
       image 'ahmed24khaled/ansible-management'
       reuseNode true
      }
     }
     steps {
      script {

       pom = readMavenPom file: "pom.xml"
       repoPath = "${pom.groupId}".replace(".", "/") + "/${pom.artifactId}"
       version = pom.version
       artifactId = pom.artifactId
       withEnv(["ANSIBLE_HOST_KEY_CHECKING=False", "APP_NAME=${artifactId}", "repoPath=${repoPath}", "version=${version}"]) {
        sh '''

          curl --silent "http://$NEXUS_URL/repository/maven-snapshots/${repoPath}/${version}/maven-metadata.xml" > tmp &&
          egrep '<value>+([0-9\\-\\.]*)' tmp > tmp2 &&
          tail -n 1 tmp2 > tmp3 &&
          tr -d "</value>[:space:]" < tmp3 > tmp4 &&
          REPO_VERSION=$(cat tmp4) &&

          export APP_SRC_URL="http://${NEXUS_URL}/repository/maven-snapshots/${repoPath}/${version}/${APP_NAME}-${REPO_VERSION}.war" &&
          ansible-playbook -v -i ./ansible_provisioning/hosts --extra-vars "host=staging" ./ansible_provisioning/playbook.yml

         '''
       }
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
