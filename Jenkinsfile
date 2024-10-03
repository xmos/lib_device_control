@Library('xmos_jenkins_shared_library@v0.32.0') _

def buildApps(appList) {
  appList.each { app ->
    dir(app)  {
      sh "cmake -G 'Unix Makefiles' -B build"
      sh "xmake -C build"
    }
  }
}

def buildHostApps(appList) {
  appList.each { app ->
    dir(app) {
      sh "cmake -G Ninja -B build"
      sh "ninja -C build"
    }
  }
}
getApproval()

pipeline {
  agent {
    label 'x86_64&&macOS'
  }
  environment {
    REPO = 'lib_device_control'
    VIEW = getViewName(REPO)
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
        script {
          hostAppList = ['usb/host', 'xscope/host']
        }
        script {
          hostAppList.each { app ->
            viewEnv() {
              dir("${REPO}/examples/${app}") {
                sh 'ls -la'
                sh "cmake -G Ninja -B build"
                sh "ninja -C build"
              }
            }
          }
        }
      }
    }
    stage('xCORE builds') {
      steps {
        script {
          appList = ['i2c', 'i2c/host_xcore', 'spi', 'usb', 'xscope']
        }
        script {
          appList.each { app ->
            dir("${REPO}/examples/${app}") {
              withTools("15.3.0") {
                withVenv {
                  sh 'cmake -G "Unix Makefiles" -B build'
                  sh "xmake -C build"
                }
              }
            }
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
