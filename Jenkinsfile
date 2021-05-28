@Library('xmos_jenkins_shared_library@v0.16.2') _
getApproval()

pipeline {
  agent {
    label 'test-catalina-jagent'
  }
  environment {
    REPO = 'lib_device_control'
    VIEW = "lib_device_control_develop"
  }
  options {
    skipDefaultCheckout()
  }
  stages {
    stage('Get view') {
      steps {
        xcorePrepareSandbox("${VIEW}", "${REPO}")
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
        dir("${REPO}/examples") {
          dir('AN01034_using_the_device_control_library_over_usb/host') {
            sh 'make -f Makefile.OSX'
          }
          dir('xscope/host') {
            viewEnv() {
              sh 'make -f Makefile.OSX'
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
      xcoreCleanSandbox()
    }
  }
}
