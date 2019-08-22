#!/bin/bash  

# [BETA]
# attempt to automate lazy triggered builds that belong to my just PUSHED contents...
# 
# [Inspired]
# ...by http://www.inanzzz.com/index.php/post/jnrg/running-jenkins-build-via-command-line

SELECT=$1

JOB=ivy-core_ci
if [ ! -z "$3" ]
  then
    JOB=$3
fi

JENKINS=zugprojenkins
URL="http://zugprojenkins/job/$JOB/"
JENKINS_USER=`whoami`

# ensure dependent binaries exist
if ! [ -x "$(command -v curl)" ]; then
  sudo apt install -y curl
fi
if ! [ -x "$(command -v jq)" ]; then
  sudo apt install -y jq
fi

# color constants
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

function getAvailableBranches()
{
  JSON=`curl -s "$URL/api/json?tree=jobs[name]"`
  BRANCHES=`echo $JSON | jq '.jobs[].name' \
   | sed -e 's|%2F|/|' \
   | sed -e 's|"||g' `
  echo -e $BRANCHES
}

function getAvailableTestJobs()
{
  JSON=`curl -s "http://$JENKINS/api/json?tree=jobs[name]"`
  JOBS=`echo $JSON | jq '.jobs[].name' | grep 'ivy-core_test' \
   | sed -e 's|%2F|/|' \
   | sed -e 's|"||g' `
  echo $JOBS
}

function triggerBuilds() {
    BRANCH=$1
    echo -e "triggering builds for ${GREEN}${BRANCH}${NC}"

    JOBS=$( getAvailableTestJobs )
    select RUN in none 'ivy-core_ci' 'ivy-core_product' $JOBS 'new view'
    do
        if [ "$RUN" == "none" ]
        then
            break
        fi
        if [ "$RUN" == "new view" ]
        then
            createView $BRANCH
            break
        fi
        RUN_JOB=${RUN}
        BRANCH_ENCODED=`encode $BRANCH`
        BUILD_URL="http://$JENKINS/job/$RUN_JOB/job/$BRANCH_ENCODED/build?delay=0sec"
        RESPONSE=`jPost --write-out %{http_code} --silent --output /dev/null -I "$BUILD_URL"`
        echo "jenkins returned HTTP code : $RESPONSE"
        
        if [ "$RESPONSE" == 404 ] ; then
            # job may requires a manual rescan to expose our new branch
            rescanBranches "http://$JENKINS/job/$RUN_JOB/"
            # re-try after re-scan:
            RESPONSE=`jPost --write-out %{http_code} --silent --output /dev/null -I "$BUILD_URL"`
            echo "jenkins returned HTTP code : $RESPONSE"
        fi
    done
}

function rescanBranches()
{
  JOB_URL=$1
  ACTION="build?delay=0"
  SCAN_URL="$JOB_URL$ACTION"
  HTTP_STATUS=`jPost --write-out %{http_code} --silent --output /dev/null -I -L "$SCAN_URL"`
  echo "triggered rescan triggered for $SCAN_URL"
  
  if [[ $HTTP_STATUS == *"200"* ]]; then
    echo "jenkins returned status $HTTP_STATUS. Waiting for index job to finish"
    ACTION="indexing/consoleText"
    until [[ $(curl --write-out --output /dev/null --silent $JOB_URL$ACTION) == *"Finished:"* ]]; do
      printf "."
      sleep 1
    done
  else
    echo "failed: Jenkins returned $HTTP_STATUS"
  fi
}

function createView()
{
  # prepare a simple view: listing all jobs of my feature branch
  BRANCH=$1
  BRANCH_ENCODED=`encode $BRANCH`
  MYVIEWS_URL="https://$JENKINS/user/${JENKINS_USER}/my-views"
  jPost --form name=test --form mode=hudson.model.ListView --form json="{'name': '${BRANCH}', 'mode': 'hudson.model.ListView', 'useincluderegex': 'on'}" "${MYVIEWS_URL}/createView"
  CONFIG_URL="${MYVIEWS_URL}/view/${BRANCH_ENCODED}/config.xml"
  curl -k -s -X GET "${CONFIG_URL}" -o viewConf.xml
  ISSUE_REGEX=$( echo $BRANCH | sed -e 's|.*/|\.*|')
  sed -e "s|<recurse>false</recurse>|<includeRegex>${ISSUE_REGEX}</includeRegex><recurse>true></recurse>|" viewConf.xml > viewConf2.xml
  jPost -H "Content-Type:text/xml" --data-binary "@viewConf2.xml"
  rm viewConf*.xml
  echo "View created: ${MYVIEWS_URL}/view/${BRANCH_ENCODED}/"
}

function jPost()
{
  if [ -z ${JENKINS_TOKEN+x} ]
  then
    echo "Jenkins API token not found as enviroment variable called 'JENKINS_TOKEN'. Therefore password for jenkins must be entered:"
    echo -n "Enter JENKINS password for $JENKINS_USER:" 
    echo -n ""
    read -s JENKINS_TOKEN
    export JENKINS_TOKEN=${JENKINS_TOKEN}
    echo ""
  fi
  
  # get XSS preventention token
  if [ -z ${CRUMB+x} ]
  then
    CRUMB=`wget -q --auth-no-challenge --user $JENKINS_USER --password $JENKINS_TOKEN --output-document - 'http://zugprojenkins/crumbIssuer/api/xml?xpath=concat(//crumbRequestField,":",//crumb)'`
    export CRUMB=${CRUMB}
  fi
  
  curl -k POST -u "$JENKINS_USER:$JENKINS_TOKEN" -H "$CRUMB" "$@"
}

function encode()
{
  echo $1 | sed -e 's|/|%2F|' 
}

BRANCHES=$( getAvailableBranches )

echo "SELECT branch of $URL"
select BRANCH_SELECTED in 're-scan' $BRANCHES
do
    if [ "$BRANCH_SELECTED" == "re-scan" ]
    then
        echo 're-scanning [beta]'
        rescanBranches $URL
        BRANCHES=$( getAvailableBranches )
    else
        triggerBuilds ${BRANCH_SELECTED}
        break
    fi
done

