@Library('xmos_jenkins_shared_library@v0.32.0') _

def buildApps(appList) {
  appList.each { app ->
    sh "cmake -G 'Unix Makefiles' -S ${app} -B ${app}/build"
    sh "xmake -C ${app}/build"
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
        dir("${REPO}/examples") {
          dir('usb/host') {
            sh 'make -f Makefile.OSX'
          }
          dir('xscope/host') {
            viewEnv() {
              sh 'cmake -G Ninja -B build'
              sh 'ninja -C build'
            }
          }
        }
      }
    }
    stage('xCORE builds (A)') {
      steps {
        dir("${REPO}") {
          // xcoreAllAppsBuild('examples')
          dir('examples') {
            xcoreCompile('i2c')
            dir('i2c') {
              xcoreCompile('host_xcore')
            }
            xcoreCompile('spi')
            xcoreCompile('usb')
            // xcoreCompile('xscope') // included in builds (B)
          }
          dir("${REPO}") {
            runXdoc('doc')
          }
        }
      }
    }
  
    stage('xCORE builds (B)') {
        steps{
          dir("${REPO}") { withTools("15.3.0") { withVenv {
            buildApps(['examples/xscope']) //TODO ideally migrate the rest of the apps to this method
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
