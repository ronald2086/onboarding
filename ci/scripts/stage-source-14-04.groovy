#!/usr/bin/env groovy

// For Playground environment set the tag and Snapshot artifact version value using TF  Workspace
// For other environment if branch is non-master then set the artifact version as Snapshot
void setEnvVars(String artifactBuildNumber) {
  setParams()
  setTagAndVersion(artifactBuildNumber)
  env.artifactBuildNumber = "${artifactBuildNumber}"
  env.fullArtifactVersion = "${env.artifactVersion}" 
  env.STARTED_BY = currentBuild.getBuildCauses().iterator().next().userName ?: "Jenkins/Parent"
  env.UBUNTU_RELEASE = '14.04'

  echo "tagId=${env.tagId}"
  echo "artifactVersion=${env.artifactVersion}"
  echo "STARTED_BY=${env.STARTED_BY}"
}

void setTagAndVersion(String artifactBuildNumber) {
  echo "gitBranch=${env.BUILD_GIT_BRANCH}"  
  env.tagId = "ems-1404-${env.ENVIRONMENT}-build-${artifactBuildNumber}"
  env.artifactVersion = "ems-1404-${env.ENVIRONMENT}-build-${artifactBuildNumber}-SNAPSHOT"
}

String folderName() {
    String[] jobPath = pwd().split('/')
    return jobPath[jobPath.length - 2]
}

void setParams() {
  String folder = folderName()
  // Handle Overrides
  // Environment
  if (params.ENVIRONMENT != null && params.ENVIRONMENT != '') {
    env.ENVIRONMENT = params.ENVIRONMENT
  } else {
    env.ENVIRONMENT = folder
  }
  echo "=== ENVIRONMENT: [${env.ENVIRONMENT}] ==="

  // Set GIT_BRANCH to dev by default if params is empty
  env.BUILD_GIT_BRANCH = 'dev'

  // set GIT_BRANCH unless overridden
  if (params.BUILD_GIT_BRANCH != null & params.BUILD_GIT_BRANCH != '') {
    env.BUILD_GIT_BRANCH = params.BUILD_GIT_BRANCH
  }
  echo "=== BUILD_GIT_BRANCH: [${env.BUILD_GIT_BRANCH}] ==="

  // DR
  if (params.DR != null && params.DR == 'true') {
    env.DR = 'true'
    env.REGION = 'us-west-2'
  } else {
    env.DR = 'false'
    env.REGION = 'us-east-1'
  }

  // region (overrides DR parameter if set)
  if (params.REGION != null && params.REGION != '') {
    env.REGION = params.REGION
  }
  echo "=== REGION: [${env.REGION}] ==="

  //AWS ACCOUNT
  if (params.AWS_ACCOUNT_ALIAS != null && params.AWS_ACCOUNT_ALIAS != '') {
    env.AWS_ACCOUNT_ALIAS = params.AWS_ACCOUNT_ALIAS
  } else if (env.ENVIRONMENT == 'playground') {
    env.AWS_ACCOUNT_ALIAS = "enl-playground"
  } else {
    env.AWS_ACCOUNT_ALIAS = "enl-${env.ENVIRONMENT}-manage"
  }
  echo "=== AWS_ACCOUNT_ALIAS: [${env.AWS_ACCOUNT_ALIAS}] ==="

  env.DEBUG_MODE = params.DEBUG_MODE != null ? params.DEBUG_MODE : 'false'
}

def checkoutAndTag() {
  echo '========Tag bitbucket with build number========'

  if (!params.EM_BRANCH.equals("master")) {
      env.SONARCUBE_TARGET_BRANCH = "master";
  } else {
      // Target branch should not be set for master
      env.SONARCUBE_TARGET_BRANCH = null;
  }

  withCredentials([sshUserPrivateKey(credentialsId: 'jenkins-bitbucket-ssh', keyFileVariable: 'KEY')]) {
    sh '''
      mkdir -p ~/.ssh
      cat "${KEY}" > ~/.ssh/id_rsa
      chmod 600 ~/.ssh/id_rsa
      echo "bitbucket.org ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAubiN81eDcafrgMeLzaFPsw2kNvEcqTKl/VqLat/MaB33pZy0y3rJZtnqwR2qOOvbwKZYKiEO1O6VqNEBxKvJJelCq0dTXWT5pbO2gDXC6h6QDXCaHo6pOHGPUy+YBaGQRGuSusMEASYiWunYN0vCAI8QaXnWMXNMdFP3jHAJH0eDsoiGnLPBlBp4TNm6rYI74nMzgz3B9IikW4WVK+dc8KZJZWYjAuORU3jc1c/NPskD2ASinf8v3xnfXeukU0sJ5N6m5E8VLjObPEO+mN2t/FZTMZLiFqPWc/ALSqnMnnhwrNi2rbfg/rd/IpL8Le3pSBne8+seeFVBoGqzHM9yXw==" >> ~/.ssh/known_hosts

      echo "Tagging with id = ${tagId}"
      echo "DEBUG_MODE:[${DEBUG_MODE}]"
      cd EM
      if [ "${DEBUG_MODE}" == "false" ]; then
        # Tag the bitbucket on latest (HEAD)
        git tag -a "${tagId}" HEAD -m "Tag created for build ${tagId}"
        git push origin "${tagId}" -f

        # Checkout from the tag
        git checkout tags/"${tagId}"
      else
        echo "=== SKIPPING CHECKOUT DEBUG_MODE ==="
      fi
      cd ..
    '''
  }
}

def processBacnetProcess() {
  echo "========Process BAcnet========="
  container('docker-manage-ubuntu14-04') {
    withCredentials([sshUserPrivateKey(credentialsId: 'jenkins-bitbucket-ssh', keyFileVariable: 'KEY')]) {
      sh '''
        mkdir -p ~/.ssh
        cat "${KEY}" > ~/.ssh/id_rsa
        chmod 600 ~/.ssh/id_rsa
        echo "bitbucket.org ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAubiN81eDcafrgMeLzaFPsw2kNvEcqTKl/VqLat/MaB33pZy0y3rJZtnqwR2qOOvbwKZYKiEO1O6VqNEBxKvJJelCq0dTXWT5pbO2gDXC6h6QDXCaHo6pOHGPUy+YBaGQRGuSusMEASYiWunYN0vCAI8QaXnWMXNMdFP3jHAJH0eDsoiGnLPBlBp4TNm6rYI74nMzgz3B9IikW4WVK+dc8KZJZWYjAuORU3jc1c/NPskD2ASinf8v3xnfXeukU0sJ5N6m5E8VLjObPEO+mN2t/FZTMZLiFqPWc/ALSqnMnnhwrNi2rbfg/rd/IpL8Le3pSBne8+seeFVBoGqzHM9yXw==" >> ~/.ssh/known_hosts

        eval `ssh-agent`
        ssh-add ${KEY}
        ssh-add -l

        # Static checkouts from support repositories. These are not expected to change.
        #/usr/bin/git clone -b Energy_Manager_Build_tag --depth 1 git@bitbucket.org:enlightedinc/bacnet.git BACNET2
        git clone -b master --depth 1 git@bitbucket.org:enlightedinc/tools.git .repository

        # Adjust the initial content of the local repositories so that the paths are correct
        # This must be done before running Maven
        mkdir BACNET2
        cd .repository
        mv em/dependencies/* .
        mv bacnet/${BACNET_RC} ../BACNET2/EnlightedBACnet.zip
        rm -rf em
        rm -rf aire

        echo "SONARCUBE_TARGET_BRANCH is set to ${SONARCUBE_TARGET_BRANCH}"
      '''
    }
  }
}

def buildCode() {
  echo "========Building code========"
  script {
    CI_ERROR = 'Build code failed'
  }
  container('docker-manage-ubuntu14-04') {
    configFileProvider([configFile(fileId: 'maven-settings', variable: 'MAVEN_SETTINGS_XML')]) {
        getNexusCreds()
        sh """
          cd EM

          echo "================== RUNNING MAVEN BUILD ========================"

          mvn -U -P deploy clean install -Dbuild.number=${BUILD_NUMBER} \
          org.cyclonedx:cyclonedx-maven-plugin:makeAggregateBom \
          org.jacoco:jacoco-maven-plugin:prepare-agent \
          org.jacoco:jacoco-maven-plugin:report \
          org.cyclonedx:cyclonedx-maven-plugin:makeAggregateBom \
          -Dorg.springframework.boot.logging.LoggingSystem=org.springframework.boot.logging.log4j2.Log4J2LoggingSystem
          
          cp ci/scripts/em_debian_aws.sh .
          cp ci/scripts/cloud_debian.sh .
          cp ci/scripts/adr_debian2.sh .
          chmod +x ./*.sh
          bash ./em_debian_aws.sh a64 ${UBUNTU_RELEASE}

          bash ./cloud_debian.sh
          bash ./adr_debian2.sh
        """
    }
  }
}

def getNexusCreds() {
  echo "======== Get Nexus Creds ========"
  container('docker-manage-ubuntu14-04'){
    withCredentials([usernamePassword(credentialsId: 'jenkins-nexus', usernameVariable: 'NPM_USERNAME', passwordVariable: 'NPM_PASSWORD')]) {
      sh """
        npm-cli-adduser --registry https://nexus.aws.enlightedinc.com/repository/npm-all/ --username $NPM_USERNAME --password $NPM_PASSWORD --email devops@enlightedinc.com
        npm config set registry https://nexus.aws.enlightedinc.com/repository/npm-all/
        cat ~/.npmrc > ${WORKSPACE}/EM/ems_react_ui/.npmrc
        echo "always-auth=true" >> ${WORKSPACE}/EM/ems_react_ui/.npmrc
      """
    }
  }
}

def showJUnitReport() {
  try{
    echo "xunit report preparation..."
    xunit (
      thresholds: [[$class: 'FailedThreshold', unstableThreshold: '0']],
      tools: [ JUnit(pattern: 'ems/**/target/surefire-reports/*.xml')]
    )
  } catch(err) {
    echo "xunit : Error $err"
  }
}

def sendSlackNotification() {
  String GIT_BRANCH_COMMITTER_NAME = sh(script: "cd ${WORKSPACE};git log -1 --pretty=format:'%ae' | xargs", returnStdout: true).trim() as String
  GIT_BRANCH_COMMITTER_NAME = "Committer: ${GIT_BRANCH_COMMITTER_NAME}"

  def GIT_MASTER_DEVELOP_BRANCHE_LIST = ["master", "develop", "origin/develop", "origin/master", "dev", "rel_em_4.2"]
  String SLACK_CHANNEL_NAME = "#manage-ubuntu-aws-build-jobs"

  String PG_WORKSPACE_OR_ENVIRONMENT_NAME = "Environment: ${env.ENVIRONMENT}"

  String BUILD_TAG_DISPLAY = "Build Tag: ${env.tagId}"
  String SERVICE_OWNER = "Owner: Sreedhar Kamishetty"
  String SLACK_ALERT_COLOR = "danger"
  String JENKINS_JOB_NAME = "Job: ${env.JOB_NAME}"
  String JENKINS_JOB_STATUS =  "Status: *${currentBuild.currentResult}*"
  String GIT_BRANCH_NAME = "Branch: ${env.BUILD_GIT_BRANCH}"
  String ERROR_DESCRIPTION = ""
  if (binding.hasVariable('CI_ERROR')) {
    ERROR_DESCRIPTION = "Error description: ${CI_ERROR}"
  }
  String JOB_STARTED_BY = "Job Started By: ${env.STARTED_BY}"
  String BUILD_REPORT = "Build Report: ${env.BUILD_URL}"

  String MANAGE_APP_URL = ""
  def JENKINS_DEPLOY_JOBS = ["DSP_Manage/dev/deploy-manage", "DSP_Playground/build-and-deploy-manage", "DSP_Manage/preprod/deploy-manage", "DSP_Manage/prod/deploy-manage"]

  if ( currentBuild.currentResult == "SUCCESS" ) {
    SLACK_ALERT_COLOR = "good"
    ERROR_DESCRIPTION = ""
  } else if ( (currentBuild.currentResult == "UNSTABLE") || (currentBuild.currentResult == "ABORTED")) {
    SLACK_ALERT_COLOR = "#eb972a"
    ERROR_DESCRIPTION = ""
  } else if ( currentBuild.currentResult == "FAILURE" ) {
    SLACK_ALERT_COLOR = "danger"
  }

  buildSummary = "${JENKINS_JOB_NAME}\n ${BUILD_TAG_DISPLAY}\n ${GIT_BRANCH_NAME}\n ${PG_WORKSPACE_OR_ENVIRONMENT_NAME}\n ${GIT_BRANCH_COMMITTER_NAME}\n ${SERVICE_OWNER}\n ${JOB_STARTED_BY}\n ${BUILD_REPORT}\n ${JENKINS_JOB_STATUS}\n ${ERROR_DESCRIPTION}"

  slackSend channel: "${SLACK_CHANNEL_NAME}", color : "${SLACK_ALERT_COLOR}", message: "${buildSummary}"

}

def jUnitAndSlackReport(){
  showJUnitReport()
  try{
    echo "Calling sendSlackNotification()..."
    sendSlackNotification()
  } catch(err) {
    echo "sendSlackNotification() : Error $err"
  }
}

return this