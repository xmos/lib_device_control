@Library('xmos_jenkins_shared_library@develop') _

getApproval()

pipeline {
  agent {
    label 'x86_64&&brew&&macOS'
  }
  environment {
    REPO = 'lib_device_control'
    VIEW = "${env.JOB_NAME.contains('PR-') ? REPO+'_'+env.CHANGE_TARGET : REPO+'_'+env.BRANCH_NAME}"
  }
  triggers {
    /* Trigger this Pipeline on changes to the repos dependencies
     *
     * If this Pipeline is running in a pull request, the triggers are set
     * on the base branch the PR is set to merge in to.
     *
     * Otherwise the triggers are set on the branch of a matching name to the
     * one this Pipeline is on.
     */
    upstream(
      upstreamProjects:
        (env.JOB_NAME.contains('PR-') ?
          "../lib_gpio/${env.CHANGE_TARGET}," +
          "../lib_i2c/${env.CHANGE_TARGET}," +
          "../lib_logging/${env.CHANGE_TARGET}," +
          "../lib_mic_array_board_support/${env.CHANGE_TARGET}," +
          "../lib_usb/${env.CHANGE_TARGET}," +
          "../lib_xassert/${env.CHANGE_TARGET}," +
          "../tools_released/${env.CHANGE_TARGET}," +
          "../tools_xmostest/${env.CHANGE_TARGET}," +
          "../xdoc_released/${env.CHANGE_TARGET}"
        :
          "../lib_gpio/${env.BRANCH_NAME}," +
          "../lib_i2c/${env.BRANCH_NAME}," +
          "../lib_logging/${env.BRANCH_NAME}," +
          "../lib_mic_array_board_support/${env.BRANCH_NAME}," +
          "../lib_usb/${env.BRANCH_NAME}," +
          "../lib_xassert/${env.BRANCH_NAME}," +
          "../tools_released/${env.BRANCH_NAME}," +
          "../tools_xmostest/${env.BRANCH_NAME}," +
          "../xdoc_released/${env.BRANCH_NAME}"),
      threshold: hudson.model.Result.SUCCESS
    )
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
      cleanWs()
    }
  }
}
