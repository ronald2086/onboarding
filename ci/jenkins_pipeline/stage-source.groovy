#!/usr/bin/env groovy

// For Playground environment set the tag and Snapshot artifact version value using TF  Workspace
// For other environment if branch is non-master then set the artifact version as Snapshot
void setEnvVars(String artifactBuildNumber) {
  setParams()
  setTagAndVersion(artifactBuildNumber)
  env.artifactBuildNumber = "${artifactBuildNumber}"
  env.fullArtifactVersion = "${env.artifactVersion}" 
  env.STARTED_BY = currentBuild.getBuildCauses().iterator().next().userName ?: "Jenkins/Parent"

  echo "tagId=${env.tagId}"
  echo "artifactVersion=${env.artifactVersion}"
  echo "STARTED_BY=${env.STARTED_BY}"
}

void setTagAndVersion(String artifactBuildNumber) {
  echo "gitBranch=${env.BUILD_GIT_BRANCH}"
  
  if (env.ENVIRONMENT == 'playground') {
      env.tagId = "pg-${params.TENANT_INSTANCE_NAME}-b${artifactBuildNumber}"
      env.artifactVersion = "${env.tagId}-SNAPSHOT"
  }  else if ( env.BUILD_GIT_BRANCH != 'master' ) {
      env.tagId = "b${artifactBuildNumber}"
      env.artifactVersion = "b${artifactBuildNumber}-SNAPSHOT"
  } else {
      env.tagId = "prod-b${artifactBuildNumber}"
      env.artifactVersion = "b${artifactBuildNumber}"
  }
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
  if (env.ENVIRONMENT == 'dev') {
    env.BUILD_GIT_BRANCH = 'develop'
  } else if (env.ENVIRONMENT != 'playground') {
    env.BUILD_GIT_BRANCH = 'master'
  }
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
  if (env.ENVIRONMENT == 'playground') {
    env.DD_MANAGE_API_KEY = "dd_api_key_dev"
    env.DD_MANAGE_APP_KEY = "dd_manage_app_app_key_dev"
  } else {
    env.DD_MANAGE_API_KEY = "dd_api_key_${env.ENVIRONMENT}"
    env.DD_MANAGE_APP_KEY = "dd_manage_app_app_key_${env.ENVIRONMENT}"
  }
  
  echo "=== DD_MANAGE_API_KEY: [${env.DD_MANAGE_API_KEY}] === DD_MANAGE_APP_KEY: [${env.DD_MANAGE_APP_KEY}]"
}

def checkoutAndTag() {
  echo '========Tag bitbucket with build number========'

  withCredentials([sshUserPrivateKey(credentialsId: 'jenkins-bitbucket-ssh', keyFileVariable: 'KEY')]) {
    sh '''
      mkdir -p ~/.ssh
      cat "${KEY}" > ~/.ssh/id_rsa
      chmod 600 ~/.ssh/id_rsa
      echo "bitbucket.org ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAubiN81eDcafrgMeLzaFPsw2kNvEcqTKl/VqLat/MaB33pZy0y3rJZtnqwR2qOOvbwKZYKiEO1O6VqNEBxKvJJelCq0dTXWT5pbO2gDXC6h6QDXCaHo6pOHGPUy+YBaGQRGuSusMEASYiWunYN0vCAI8QaXnWMXNMdFP3jHAJH0eDsoiGnLPBlBp4TNm6rYI74nMzgz3B9IikW4WVK+dc8KZJZWYjAuORU3jc1c/NPskD2ASinf8v3xnfXeukU0sJ5N6m5E8VLjObPEO+mN2t/FZTMZLiFqPWc/ALSqnMnnhwrNi2rbfg/rd/IpL8Le3pSBne8+seeFVBoGqzHM9yXw==" >> ~/.ssh/known_hosts

      echo "Tagging with id = ${tagId}"
      echo "DEBUG_MODE:[${DEBUG_MODE}]"
      if [ "${DEBUG_MODE}" == "false" ]; then
        # Tag the bitbucket on latest (HEAD)
        git tag -a "${tagId}" HEAD -m "Tag created for build ${tagId}"
        git push origin "${tagId}" -f

        # Checkout from the tag
        git checkout tags/"${tagId}"
      else
        echo "=== SKIPPING CHECKOUT DEBUG_MODE ==="
      fi
    '''
  }
}

def scanTerraform() {
  echo "========Scanning Terraform========"
  container('checkov') {
      sh "checkov --config-file .checkov.yaml"
  }
}

def buildCode() {
  echo "========Building code========"
  script {
    CI_ERROR = 'Build code failed'
  }
  container('manage-jdk8-npm') {
    configFileProvider([configFile(fileId: 'maven-settings', variable: 'MAVEN_SETTINGS_XML')]) {
      getNexusCreds()
      sh '''
        echo "  ------ Build Manage Code --------------"
        artifactId=$(mvn help:evaluate -Dexpression=project.artifactId -q -DforceStdout)
        mvn -U -P deploy clean install -s $MAVEN_SETTINGS_XML -Dbuild.number=${BUILD_NUMBER}
      '''
    }
  }

}

def prepareZipBundle(){
  echo "========Manage application & infra zip bundle preparation========"
  script {
    CI_ERROR = 'Failed at zip bundle preparation'
  }
  container('manage-jdk8-npm') {
    sh (returnStdout: true, script: "${WORKSPACE}/ci/jenkins_pipeline/manage_builder.sh").trim()
  }
}

def setupTerraform() {
    echo "========Setup terraform========"
    script {
        CI_ERROR = "Setup tools failed"
        def tfHome = tool 'terraform-0.13.6-amd64'
        env.PATH = "${tfHome}:${env.PATH}"
    }
    withCredentials([sshUserPrivateKey(credentialsId: 'jenkins-bitbucket-ssh', keyFileVariable: 'KEY')]) {
    sh """
      mkdir -p ~/.ssh
      cat "${KEY}" > ~/.ssh/id_rsa
      chmod 600 ~/.ssh/id_rsa
      echo "bitbucket.org ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAubiN81eDcafrgMeLzaFPsw2kNvEcqTKl/VqLat/MaB33pZy0y3rJZtnqwR2qOOvbwKZYKiEO1O6VqNEBxKvJJelCq0dTXWT5pbO2gDXC6h6QDXCaHo6pOHGPUy+YBaGQRGuSusMEASYiWunYN0vCAI8QaXnWMXNMdFP3jHAJH0eDsoiGnLPBlBp4TNm6rYI74nMzgz3B9IikW4WVK+dc8KZJZWYjAuORU3jc1c/NPskD2ASinf8v3xnfXeukU0sJ5N6m5E8VLjObPEO+mN2t/FZTMZLiFqPWc/ALSqnMnnhwrNi2rbfg/rd/IpL8Le3pSBne8+seeFVBoGqzHM9yXw==" >> ~/.ssh/known_hosts

      echo '===== Stage: Setup Tools ====='
      #!/bin/bash
      echo "===== terraform version ====="
      terraform --version
    """
    }
}

def setupTools() {
  echo "========Setup terraform========"
  script {
    CI_ERROR = "Setup tools failed"
    def tfHome = tool 'terraform-0.13.6-amd64'
    env.PATH = "${tfHome}:${env.PATH}"
    awsAccountId = awsAccountIds "${AWS_ACCOUNT_ALIAS}"
  }
  withCredentials([sshUserPrivateKey(credentialsId: 'jenkins-bitbucket-ssh', keyFileVariable: 'KEY')]) {
    sh """
      mkdir -p ~/.ssh
      cat "${KEY}" > ~/.ssh/id_rsa
      chmod 600 ~/.ssh/id_rsa
      echo "bitbucket.org ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAubiN81eDcafrgMeLzaFPsw2kNvEcqTKl/VqLat/MaB33pZy0y3rJZtnqwR2qOOvbwKZYKiEO1O6VqNEBxKvJJelCq0dTXWT5pbO2gDXC6h6QDXCaHo6pOHGPUy+YBaGQRGuSusMEASYiWunYN0vCAI8QaXnWMXNMdFP3jHAJH0eDsoiGnLPBlBp4TNm6rYI74nMzgz3B9IikW4WVK+dc8KZJZWYjAuORU3jc1c/NPskD2ASinf8v3xnfXeukU0sJ5N6m5E8VLjObPEO+mN2t/FZTMZLiFqPWc/ALSqnMnnhwrNi2rbfg/rd/IpL8Le3pSBne8+seeFVBoGqzHM9yXw==" >> ~/.ssh/known_hosts

      echo '===== Stage: Setup Tools ====='
      #!/bin/bash
      echo "===== terraform version ====="
      terraform --version
      echo "===== awscli version ====="
      aws --version
      echo "===== aws sts get-caller-identity ====="
      aws sts get-caller-identity
      echo '===== get '${AWS_ACCOUNT_ALIAS}' admin role creds ====='
      aws sts assume-role --role-arn 'arn:aws:iam::${awsAccountId}:role/Deployer' --role-session-name 'jenkins' > assume_role.json

    """
  }
}

def getMavenRepo() {
  echo "========Getting Correct Maven Repo========"
  String mavenRepo = ""
  switch (env.ENVIRONMENT) {
    case ['preprod', 'prod']:
      echo '=== maven-releases ==='
      mavenRepo = 'maven-releases'
      break
    default:
      echo '=== maven-snapshots ==='
      mavenRepo = 'maven-snapshots'
      break
  }
  env.mavenRepo = mavenRepo
}

def uploadArtifacts() {
  echo "========Uploading Artifacts========"
  script {
    CI_ERROR = "Upload artifacts failed"
  }
  if (env.DEBUG_MODE == 'false') {
    container('manage-jdk8-npm') {
      configFileProvider([configFile(fileId: 'maven-settings', variable: 'MAVEN_SETTINGS_XML')]) {
        getMavenRepo()

        sh '''
            echo "------------upload artifacts-----------------"
            manageAppVersion=$(mvn help:evaluate -Dexpression=currentVersion -q -DforceStdout)
            if [ ! -f "${WORKSPACE}/nexus_final_zip/manage-app-infra-${artifactVersion}-${manageAppVersion}.zip" ]
            then
              echo "Required nexus uploadable zip file not exist, please check build pipeline step"
              exit 1
            fi
            
            mvn deploy:deploy-file -DgroupId=com.enlightedinc.dsp -DartifactId=manage-app-infra-bundle  -DgeneratePom=true -Dpackaging=zip -DrepositoryId=${mavenRepo} -Dversion=${artifactVersion} -Durl=https://nexus.aws.enlightedinc.com/repository/${mavenRepo}/ -Dfile=${WORKSPACE}/nexus_final_zip/manage-app-infra-${artifactVersion}-${manageAppVersion}.zip -DskipTests -s $MAVEN_SETTINGS_XML
           '''
      }
    } //container('manage-jdk8-npm')
  } else {
    echo "====== SKIPPED DUE TO DEBUG_MODE ======"
  }
}

def getFromNexus() {
  echo "========Downloading Artifacts from Nexus========\""
  getMavenRepo()

  script {
    CI_ERROR = "Get from nexus failed"
  }
  if (env.DEBUG_MODE == 'false') {
    container('manage-jdk8-npm') {
      configFileProvider([configFile(fileId: 'maven-settings', variable: 'MAVEN_SETTINGS_XML')]) {
        sh '''
          mkdir -p nexus_manage_zip_download
          echo "---------Downloading com.enlightedinc.dsp:manage-app-infra-bundle:${artifactVersion}:zip from nexus---------"
          mvn dependency:get -DrepositoryId=${mavenRepo} -Dartifact=com.enlightedinc.dsp:manage-app-infra-bundle:${artifactVersion}:zip -Dtransitive=false -Ddest=./nexus_manage_zip_download -DremoteRepositories=https://nexus.aws.enlightedinc.com/repository/${mavenRepo}/ -s $MAVEN_SETTINGS_XML
          
          chmod -R 777 ${WORKSPACE}/nexus_manage_zip_download
          # extract manage zip file here....
          cd ${WORKSPACE}/nexus_manage_zip_download
          echo "---------Unzipping manage zip bundle--------"
          # unzip -o "${artifactId}"-*.zip
          for z in *.zip; do unzip -o $z; done
          chmod -R 777 ${WORKSPACE}/nexus_manage_zip_download
          echo "---------Ready for deplyment into beanstalk environment--------"
        '''
    }
    }
  } else {
    echo "====== SKIPPED DUE TO DEBUG_MODE ======"
  }
}

def getNexusCreds() {
   echo "======== Get Nexus Creds ========"
   container('manage-jdk8-npm'){
     withCredentials([usernamePassword(credentialsId: 'jenkins-nexus', usernameVariable: 'NPM_USERNAME', passwordVariable: 'NPM_PASSWORD')]) {
      sh """
        npm-cli-adduser --registry https://nexus.aws.enlightedinc.com/repository/npm-all/ --username $NPM_USERNAME --password $NPM_PASSWORD --email devops@enlightedinc.com
        npm config set registry https://nexus.aws.enlightedinc.com/repository/npm-all/
        cat ~/.npmrc > ${WORKSPACE}/ems_react_ui/.npmrc
        echo "always-auth=true" >> ${WORKSPACE}/ems_react_ui/.npmrc
      """
     }
   }
}

def deploy() {
  script {
    env.AWS_ACCESS_KEY_ID = sh (returnStdout: true, script: 'cat assume_role.json | jq -r ".Credentials.AccessKeyId"').trim()
    env.AWS_SECRET_ACCESS_KEY = sh (returnStdout: true, script: 'cat assume_role.json | jq -r ".Credentials.SecretAccessKey"').trim() //pragma: allowlist secret (DO NOT DELETE, THIS IS FOR DETECT_SECRETS PRE_COMMIT HOOK)
    env.AWS_SESSION_TOKEN = sh (returnStdout: true, script: 'cat assume_role.json | jq -r ".Credentials.SessionToken"').trim()
    CI_ERROR = "Deployment failed"
    echo "=== DR Value:[${env.DR}]"
  }
  withCredentials([string(credentialsId: "${env.DD_MANAGE_API_KEY}", variable: 'DD_API_KEY_TEXT'),
                   string(credentialsId: "${env.DD_MANAGE_APP_KEY}", variable: 'DD_APP_KEY_TEXT')]) {
        sh '''

          cd ${WORKSPACE}/nexus_manage_zip_download
          export TF_VAR_datadog_api_key="${DD_API_KEY_TEXT}"
          export TF_VAR_datadog_app_key="${DD_APP_KEY_TEXT}"
          if ls ${WORKSPACE}/nexus_manage_zip_download/manage-app-bundle*.zip 1> /dev/null 2>&1; then
            echo "Manage deployment zip $manage_app_zip_file_path bundle available to use in terraform"
            manage_app_zip_file_path=`realpath $(find . -type f -name manage-app-bundle*.zip -print -quit)`
            export TF_VAR_manage_application_bundle="${manage_app_zip_file_path}"
          else
            echo "Manage deployment bundle not exist so default draft/sample application will be deployed"
            export TF_VAR_manage_application_bundle=""
          fi
          if [ ! -z "${TENANT_RDS_SNAPSHOT_IDENTIFIER}" ]; then
            export TF_VAR_tenant_rds_snapshot_identifier="${TENANT_RDS_SNAPSHOT_IDENTIFIER}"
          fi
          export AWS_REGION="${REGION}"
          export TENANT_INSTANCE_NAME="${TENANT_INSTANCE_NAME}"
          cd ${WORKSPACE}/nexus_manage_zip_download/manage_infra

          echo "starting deployment script...."
          if [ "${ENVIRONMENT}" == "playground" ]; then
            cd live/playground
            sh manage_playground.sh
          else
            cd live/base
            sh manage_deploy.sh
          fi
          
          export manage_app_access_url=`terraform output manage_application_accessible_url`
          echo `terraform output manage_uuid`> ${WORKSPACE}/nexus_manage_zip_download/manage_infra/manage_uuid.out
          echo `terraform output pca_arn`> ${WORKSPACE}/nexus_manage_zip_download/manage_infra/pca_arn.out
          echo `terraform output iot_consumer_cert_arn`> ${WORKSPACE}/nexus_manage_zip_download/manage_infra/iot_consumer_cert_arn.out

    '''
    }
    script {
        env.CLIENT_ID = sh (returnStdout: true, script: 'cat ${WORKSPACE}/nexus_manage_zip_download/manage_infra/manage_uuid.out').trim()
        env.PCA_ARN = sh (returnStdout: true, script: 'cat ${WORKSPACE}/nexus_manage_zip_download/manage_infra/pca_arn.out').trim()
        env.CERT_ARN = sh (returnStdout: true, script: 'cat ${WORKSPACE}/nexus_manage_zip_download/manage_infra/iot_consumer_cert_arn.out').trim()
    }
  
}

def deployBootstrap() {
  script {
    env.AWS_ACCESS_KEY_ID = sh(returnStdout: true, script: 'cat assume_role.json | jq -r ".Credentials.AccessKeyId"').trim()
    env.AWS_SECRET_ACCESS_KEY = sh(returnStdout: true, script: 'cat assume_role.json | jq -r ".Credentials.SecretAccessKey"').trim() //pragma: allowlist secret (DO NOT DELETE, THIS IS FOR DETECT_SECRETS PRE_COMMIT HOOK)
    env.AWS_SESSION_TOKEN = sh(returnStdout: true, script: 'cat assume_role.json | jq -r ".Credentials.SessionToken"').trim()
    CI_ERROR = "Bootstrap Deployment failed"
    echo "=== DR Value:[${env.DR}]"
  }
  sh '''

      cd ${WORKSPACE}/nexus_manage_zip_download/manage_infra/live/base/bootstrap

      if [ ! -z "${REGION}" ]; then
        export TF_VAR_region="${REGION}"
      fi

      # terraform init
      echo "DR Value:[${DR}]"
      if [ "${DR}" == "true" ]; then
        export VARFILENAME="${ENVIRONMENT}dr.tfvars"
      else
        export VARFILENAME="${ENVIRONMENT}.tfvars"
      fi
      terraform init -input=false

      export TF_VAR_tenant_instance_name="${TENANT_INSTANCE_NAME}"
      terraform plan -input=false -var-file=./${VARFILENAME}
      terraform apply -input=false --auto-approve -var-file=./${VARFILENAME}

    '''
}

def destroy() {
  script {
    env.AWS_ACCESS_KEY_ID = sh (returnStdout: true, script: 'cat assume_role.json | jq -r ".Credentials.AccessKeyId"').trim()
    env.AWS_SECRET_ACCESS_KEY = sh (returnStdout: true, script: 'cat assume_role.json | jq -r ".Credentials.SecretAccessKey"').trim() //pragma: allowlist secret (DO NOT DELETE, THIS IS FOR DETECT_SECRETS PRE_COMMIT HOOK)
    env.AWS_SESSION_TOKEN = sh (returnStdout: true, script: 'cat assume_role.json | jq -r ".Credentials.SessionToken"').trim()
    CI_ERROR = "Destroy failed"
  }
  withCredentials([string(credentialsId: "${env.DD_MANAGE_API_KEY}", variable: 'DD_API_KEY_TEXT'),
                   string(credentialsId: "${env.DD_MANAGE_APP_KEY}", variable: 'DD_APP_KEY_TEXT')]) {
        sh '''

          cd ${WORKSPACE}/nexus_manage_zip_download
          export TF_VAR_datadog_api_key="${DD_API_KEY_TEXT}"
          export TF_VAR_datadog_app_key="${DD_APP_KEY_TEXT}"
          if ls ${WORKSPACE}/nexus_manage_zip_download/manage-app-bundle*.zip 1> /dev/null 2>&1; then
            echo "Manage deployment zip $manage_app_zip_file_path bundle available to use in terraform"
            manage_app_zip_file_path=`realpath $(find . -type f -name manage-app-bundle*.zip -print -quit)`
            export TF_VAR_manage_application_bundle="${manage_app_zip_file_path}"
          else
            echo "Manage deployment bundle not exist so default draft application will be destroyed"
            export TF_VAR_manage_application_bundle=""
          fi
          cd ${WORKSPACE}/nexus_manage_zip_download/manage_infra
          export AWS_REGION="${REGION}"
          export TENANT_INSTANCE_NAME="${TENANT_INSTANCE_NAME}"
          echo "starting deployment script...."
          if [ "${ENVIRONMENT}" == "playground" ]; then
            cd live/playground
            sh manage_playground.sh destroy
          else
            cd live/base
            sh manage_deploy.sh destroy
          fi

        '''
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

def showIntegrationTestReport() {
  try{
    echo "xunit report preparation..."
  } catch(err) {
    echo "xunit : Error $err"
  }

}

def sendSlackNotification() {

    String GIT_BRANCH_COMMITTER_NAME = sh(script: "cd ${WORKSPACE};git log -1 --pretty=format:'%ae' | xargs", returnStdout: true).trim() as String
    GIT_BRANCH_COMMITTER_NAME = "Committer: ${GIT_BRANCH_COMMITTER_NAME}"

    def GIT_MASTER_DEVELOP_BRANCHE_LIST = ["master", "develop", "origin/develop", "origin/master", "dev"]
    String SLACK_CHANNEL_NAME = "#dsp-manage-jenkins-branch-builds"
    if ( GIT_MASTER_DEVELOP_BRANCHE_LIST.contains(env.BUILD_GIT_BRANCH) ) {
      SLACK_CHANNEL_NAME = "#dsp-jenkins-manage-dev-prepod"
    }
    if (params.ENVIRONMENT == "prod") {
      SLACK_CHANNEL_NAME = "#dsp-jenkins-manage-production"
    }

    String PG_WORKSPACE_OR_ENVIRONMENT_NAME = "Environment: ${env.ENVIRONMENT}"
    if ( (params.ENVIRONMENT == "playground") && (params.TENANT_INSTANCE_NAME != null) ) {
      PG_WORKSPACE_OR_ENVIRONMENT_NAME = "Environment: ${env.ENVIRONMENT}-${params.TENANT_INSTANCE_NAME}"
    }

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
    String TENANT_INSTANCE_NAME = "Tenant Instance Name: ${params.TENANT_INSTANCE_NAME}"

    String MANAGE_APP_URL = ""
    def JENKINS_DEPLOY_JOBS = ["DSP_Manage/dev/deploy-manage", "DSP_Playground/build-and-deploy-manage", "DSP_Manage/preprod/deploy-manage", "DSP_Manage/prod/deploy-manage"]
    def isDeploymentAndAppUrlExist = fileExists "${WORKSPACE}/nexus_manage_zip_download/manage_infra/live"
    if ( JENKINS_DEPLOY_JOBS.contains(env.JOB_NAME)  &&  (isDeploymentAndAppUrlExist) ) {
      if ( (currentBuild.currentResult == "SUCCESS") || (currentBuild.currentResult == "UNSTABLE") ) {
        if ( (params.ENVIRONMENT == "playground") && (params.TENANT_INSTANCE_NAME != null) ) {
          MANAGE_APP_URL = sh(script: "cd ${WORKSPACE}/nexus_manage_zip_download/manage_infra/live/playground; terraform output manage_application_accessible_url", returnStdout: true).trim() as String
        } else {
          MANAGE_APP_URL = sh(script: "cd ${WORKSPACE}/nexus_manage_zip_download/manage_infra/live/base; terraform output manage_application_accessible_url", returnStdout: true).trim() as String
        }
        MANAGE_APP_URL = "${MANAGE_APP_URL} \n"
      }
    }

    if ( currentBuild.currentResult == "SUCCESS" ) {
      SLACK_ALERT_COLOR = "good"
      ERROR_DESCRIPTION = ""
    } else if ( (currentBuild.currentResult == "UNSTABLE") || (currentBuild.currentResult == "ABORTED")) {
      SLACK_ALERT_COLOR = "#eb972a"
      ERROR_DESCRIPTION = ""
    } else if ( currentBuild.currentResult == "FAILURE" ) {
      SLACK_ALERT_COLOR = "danger"
    }

    buildSummary = "${JENKINS_JOB_NAME}\n ${BUILD_TAG_DISPLAY}\n ${GIT_BRANCH_NAME}\n ${PG_WORKSPACE_OR_ENVIRONMENT_NAME}\n ${GIT_BRANCH_COMMITTER_NAME}\n ${SERVICE_OWNER}\n ${JOB_STARTED_BY}\n ${BUILD_REPORT}\n ${TENANT_INSTANCE_NAME}\n ${MANAGE_APP_URL} ${JENKINS_JOB_STATUS}\n ${ERROR_DESCRIPTION}"

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
