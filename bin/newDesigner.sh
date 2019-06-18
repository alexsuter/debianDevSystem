#!/bin/bash  

source jenkinsGet.sh

JOB=ivy-core_release-dev
if [ ! -z "$1" ]
  then
    JOB=$1
fi

BRANCH=master
if [ ! -z "$2" ]
  then
    BRANCH=$2
fi

JENKINS=zugprojenkins
ARTIFACT=designer
ARTIFACT_PATTERN=AxonIvyDesigner.*_MacOSX-BETA_x64.zip

jenkinsGet $JENKINS $JOB $BRANCH $ARTIFACT $ARTIFACT_PATTERN
