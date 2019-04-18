#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
brew update

brew tap caskroom/cask

# open jdk
brew tap AdoptOpenJDK/openjdk
brew cask install adoptopenjdk8

brew install maven
#sudo apt install -y openjfx
brew cask install visualvm

# git
git config --global core.editor "nano"
#$DIR/updateGitKraken.sh

# composite installers
#$DIR/docker-ce.sh
#$DIR/updatePostman.sh
#$DIR/eclipseRCP.sh
#$DIR/eclipseRCPTT.sh
#$DIR/geckodriver-install.sh

# interactive:
#echo "select jdk8 as default JRE!"
#sudo update-alternatives --config java
#$DIR/oxygenXmlAuthor.sh

