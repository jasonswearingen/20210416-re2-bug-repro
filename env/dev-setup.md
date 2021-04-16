- [docker based development](#docker-based-development)
  - [how to make a project docker container dev based](#how-to-make-a-project-docker-container-dev-based)
  - [adding project to local dev machine](#adding-project-to-local-dev-machine)
- [first time os initializations](#first-time-os-initializations)
- [opening project on local dev machine](#opening-project-on-local-dev-machine)
  - [using the docker vscode extension](#using-the-docker-vscode-extension)
  - [using docker](#using-docker)
  - [access project files from windows](#access-project-files-from-windows)
  - [use sourcetree or other gui git from windows](#use-sourcetree-or-other-gui-git-from-windows)


# docker based development
- get github personal access token, to login via vscode
- setup container based workflow (vscode container extension, docker desktop)
- install docker extension to start/attach docker containers from vscode

## how to make a project docker container dev based
https://code.visualstudio.com/docs/remote/containers
- can start by just to follow the "adding project ot local dev machine" and then checkin the .devcontainer it generates.   
  - however this won't include init scripts, so that will need to be done manually
- easiest is to copy the .devcontainer based workflow from another project (hopefully can just copy ```pjsc-dashboard```)

## adding project to local dev machine
- Run > Remote-Container clone repo into container volume  (eg: ```https://github.com/Novaleaf/pjsc-dashboard```)
- ** be sure to ```clone in docker volume``` not mount your folder to docker ** because of perf and bugs (file watching won't work)
  - to make storage-locations consistent for all devs, choose a shared container volume, use default "vsc-remote-containers" 
  - run dev-env-init.sh script found under .devcontainer/scripts (if not auto-run by the devcontainer)
  

# first time os initializations  
- run ```sudo ./env/ubuntu/basic-os-setup-20-04.sh```
- run ```sudo ./env/ubuntu/devenv-node.sh```
  
# opening project on local dev machine

## using the docker vscode extension
- run vscode
- select the container via the docker plugin, start, then attach to it.  it should create a new vscode window

## using docker
- run docker desktop, start the container
- connect using docker CLI
- from vscode (win) choose Remote Containers > attach to running container
- go to the project folder (eg: ```/workspaces/pjsc-dashboard``) and run ```code .```

## access project files from windows
when docker container is running, can navigate to ```\\wsl$\docker-desktop-data\version-pack-data\community\docker\volumes\vsc-remote-containers\_data``` and should see your container there

## use sourcetree or other gui git from windows
add the project's folder to sourcetree, for example ```\\wsl$\docker-desktop-data\version-pack-data\community\docker\volumes\vsc-remote-containers\_data\pjsc-dashboard```  
just be sure to have line-endings set to unix 


  
