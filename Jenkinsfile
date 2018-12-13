@Library('xmos_jenkins_shared_library@master') _
pipeline {
  agent {
    label 'x86&&macOS&&Apps'
  }
  environment {
    VIEW = 'device_control'
    REPO = 'lib_device_control'
  }
  options {
    skipDefaultCheckout()
  }
  stages {
    stage('Get view') {
      steps {
        prepareAppsSandbox("${VIEW}", "${REPO}")
      }
    }
    stage('Library checks') {
      steps {
        xcoreLibraryChecks("${REPO}")
      }
    }
    stage('Tests') {
      steps {
        runXmostest("${REPO}", 'tests')
      }
    }
    stage('Host builds') {
      steps {
        dir("${REPO}") {
          dir('examples') {
            dir('AN01034_using_the_device_control_library_over_usb') {
              dir('host') {
                sh 'make -f Makefile.OSX'
              }
            }
            dir('xscope') {
              dir('host') {
                viewEnv() {
                  sh 'make -f Makefile.OSX'
                }
              }
            }
          }
        }
      }
    }
    stage('xCORE builds') {
      steps {
        dir("${REPO}") {
          // xcoreAllAppsBuild('examples')
          dir('examples') {
            xcoreCompile('i2c')
            dir('i2c') {
              xcoreCompile('host_xcore')
            }
            xcoreCompile('xscope')
          }
          xcoreAllAppNotesBuild('examples')
          dir("${REPO}") {
            runXdoc('doc')
          }
        }
      }
    }
  }
  post {
    success {
      updateViewfiles()
    }
    cleanup {
      cleanWs()
    }
  }
}
