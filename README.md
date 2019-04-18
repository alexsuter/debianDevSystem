# OSX DevSystem
scripts to turn your OSX desktop into a java dev environment up and running in seconds.
first step towards an adaption that runs on a MAC with homebrew installed.

## Scope
The script are designed to work for me in my current working environment ... feel free to get inspired, but don't expect the scripts to work under any circumstances...

## Tested
- Mac High Sierra (10.13.6)

## How to use
1. install [homebrew](https://brew.sh/): `/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"`
2. clone or download this repo into your user home (e.g. /home/rew/debianDevSystem):
`git clone https://github.com/ivy-rew/debianDevSystem.git`
3. switch to the osx branch: `git checkout homebrewDevSystem`
4. run a cool composite installer script `debAdmin.sh`, `debCommunicator.sh` or `debEnv.sh`
5. manually add the line `export PATH=$PATH:/home/rew/debianDevSystem/bin` to `~/.bashrc`.
6. optionally copy the `.bash_aliases` file into your user home dir.
7. use the installed tools...
