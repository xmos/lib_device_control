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
      defaultValue: 'v8.0.1',
      description: 'xmosdoc version'
    )
    string(
      name: 'INFR_APPS_VERSION',
      defaultValue: 'v3.3.0',
      description: 'The infr_apps version'
    )
  }

  stages {
    stage('🏗️ Build and test') {
      parallel {
        stage('Linux x86_64 checks, tests and builds') {
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
                runForEach(['i2c/device', 'i2c/host_xcore', 'spi/device', 'usb/device', 'xscope/device']) { app ->
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
                        
                        // Build the legacy project is the test for xcommon support
                        dir("legacy_build_test") {
                          sh "xmake -j"
                        }
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
            stage("Archive sandbox") {
              steps {
                archiveSandbox(REPO_NAME)
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
          post {
            cleanup {
              xcoreCleanSandbox()
            }
          }
        } // Mac arm64 host builds

        stage('Win64 host builds') {
          agent {
            label 'sw-bld-win0'
          }
          steps {
            println "Stage running on ${env.NODE_NAME}"

            dir(REPO_NAME){
              checkoutScmShallow()
              withVS('vcvars64.bat') {
                dir("examples/usb/host") {
                  sh "cmake -G Ninja -B build"
                  sh "ninja -C build"
                }
                withTools(params.TOOLS_VERSION) {
                  dir("examples/xscope/host") {
                    sh "cmake -G Ninja -B build"
                    sh "ninja -C build"
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
        } // Win64 host builds

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
