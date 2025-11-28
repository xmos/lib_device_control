@Library('xmos_jenkins_shared_library@v0.43.3') _

getApproval()

def runForEach(folders, Closure body) {
  folders.each { app -> body(app) }
}

pipeline {
  agent none

  options {
    skipDefaultCheckout()
    timestamps()
    buildDiscarder(xmosDiscardBuildSettings(onlyArtifacts=false))
  }

  environment {
    REPO_NAME = 'lib_device_control'
  } // environment

  parameters {
    string(
      name: 'TOOLS_VERSION',
      defaultValue: '15.3.1',
      description: 'XTC tools version'
    )
    string(
      name: 'XMOSDOC_VERSION',
      defaultValue: 'v8.0.0',
      description: 'xmosdoc version'
    )
    string(
      name: 'INFR_APPS_VERSION',
      defaultValue: 'v3.2.1',
      description: 'The infr_apps version'
    )
  }

  stages {
    stage('Cross-platform builds and tests') {
      parallel {
        stage('Library checks, tests and Linux x86_64 host builds') {
          agent {
            label 'linux && 64 && documentation'
          }

          stages {
            stage("Checkout") {
              steps {
                println "Stage running on ${env.NODE_NAME}"

                dir(REPO_NAME) {
                  checkoutScmShallow()
                }
              }
            }
            stage('XCORE builds') {
              steps {
                // build all the supported firmware applications
                runForEach(['i2c', 'i2c/host_xcore', 'spi', 'usb', 'xscope']) { app ->
                  withTools(params.TOOLS_VERSION) { // the XTC tools are necessary to build the XSCOPE host application
                    dir("${REPO_NAME}/examples/${app}") {
                      xcoreBuild()
                    }
                  }
                }
              }
            }
            stage('Repo checks') {
              steps {
                warnError("Repo checks failed") {
                  runRepoChecks("${WORKSPACE}/${REPO_NAME}")
                }
              }
            }
            stage('Doc build') {
              steps {
                dir(REPO_NAME) {
                  buildDocs()
                }
              }
            }
            stage('Tests') {
              steps {
                dir(REPO_NAME) {
                  createVenv(reqFile: "requirements.txt")
                  withVenv {
                    withTools(params.TOOLS_VERSION) {
                      dir("tests") {
                        runPytest("--dist worksteal")
                      }
                    }
                  }
                }
              }
            }
            stage('Linux x86_64 host builds') {
              steps {
                // build all the supported host applications
                runForEach(['usb', 'xscope']) { app ->
                  withTools(params.TOOLS_VERSION) { // the XTC tools are necessary to build the XSCOPE host application
                    dir("${REPO_NAME}/examples/${app}/host") {
                      sh "cmake -B build"
                      sh "make -C build"
                    }
                  }
                }
              }
            }
          }
          post {
            cleanup {
              xcoreCleanSandbox()
            }
          }
        }

        stage('RPI host builds') {
          agent {
            label 'armv7l && raspian'
          }
          stages {
            stage('RPI Build') {
              steps {
                println "Stage running on ${env.NODE_NAME}"
                dir(REPO_NAME){
                  checkoutScmShallow()
                  // build all the supported host applications
                  runForEach(['i2c/host_rpi', 'spi/host']) { app ->
                    dir("examples/${app}") {
                        sh "cmake -B build"
                        sh "make -C build"
                    }
                  }
                }
              }
            }
          }
          post {
            cleanup {
              xcoreCleanSandbox()
            }
          }
        } // RPI host builds

        stage('Mac x86_64 host builds') {
          agent {
            label 'macOS && x86_64'
          }
          stages {
            stage('Mac x86_64 Build') {
              steps {
                println "Stage running on ${env.NODE_NAME}"
                dir(REPO_NAME){
                  checkoutScmShallow()
                  // build all the supported host applications
                  runForEach(['usb', 'xscope']) { app ->
                    withTools(params.TOOLS_VERSION) { // the XTC tools are necessary to build the XSCOPE host application
                      dir("examples/${app}/host") {
                        sh "cmake -B build"
                        sh "make -C build"
                      }
                    }
                  }
                }
              }
            }
          }
          post {
            cleanup {
              xcoreCleanSandbox()
            }
          }
        } // Linux x86_64 host builds

        stage('Mac arm64 host builds') {
          agent {
            label 'macos && arm64'
          }
          stages {
            stage('Mac arm64 Build') {
              steps {
                println "Stage running on ${env.NODE_NAME}"
                dir(REPO_NAME){
                  checkoutScmShallow()
                  // build all the supported host applications
                  runForEach(['usb', 'xscope']) { app ->
                    withTools(params.TOOLS_VERSION) { // the XTC tools are necessary to build the XSCOPE host application
                      dir("examples/${app}/host") {
                        sh "cmake -B build"
                        sh "make -C build"
                      }
                    }
                  }
                }
              }
            }
          }
          post {
            cleanup {
              xcoreCleanSandbox()
            }
          }
        } // Mac arm64 host builds

        stage('Win32 host builds') {
          agent {
            label 'sw-bld-win0'
          }
          stages {
             stage('Win32 Build') {
              steps {
                println "Stage running on ${env.NODE_NAME}"

                dir(REPO_NAME){
                  checkoutScmShallow()
                  // Build the USB host example for 32 bit as libusb is 32 bit
                  withVS('vcvars32.bat') {
                    dir("examples/usb/host") {
                      sh "cmake -G Ninja -B build"
                      sh "ninja -C build"
                    }
                  }
                  // Build the XSCOPE host example for 64 bit as XTC tools  32 bit
                  withVS('vcvars64.bat') {
                    withTools(params.TOOLS_VERSION) {
                      dir("examples/xscope/host") {
                        sh "cmake -G Ninja -B build"
                        sh "ninja -C build"
                      }
                    }
                  }
                }
              }
            }
          }
          post {
            cleanup {
              xcoreCleanSandbox()
            }
          }
        } // Win32 host builds

      } // parallel
    } // Cross-platform Builds & Tests
    
    stage('🚀 Release') {
      when {
        expression { triggerRelease.isReleasable() }
      }
      steps {
        triggerRelease()
      }
    }
  } // stages
}
