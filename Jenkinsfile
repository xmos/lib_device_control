@Library('xmos_jenkins_shared_library@v0.32.0') _

def buildApps(appList) {
  appList.each { app ->
    sh "cmake -G 'Unix Makefiles' -S ${app} -B ${app}/build"
    sh "xmake -C ${app}/build"
  }
}

def buildHostApps(appList) {
  appList.each { app ->
    sh "cmake -G Ninja -B build"
    sh "ninja -C build"
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
        appList = ['usb/host', 'xscope/host']
        dir("${REPO}/examples") {
          buildHostApps(appList)
        }
      }
    }

    stage('xCORE builds') {
        steps{
          appList = ['i2c', 'i2c/host_xcore', 'spi', 'usb', 'xscope']
          dir("${REPO}/examples") { withTools("15.3.0") { withVenv {
            buildApps(appList)
          } } } // venv, tools, dir
        } // steps
      } // build
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
