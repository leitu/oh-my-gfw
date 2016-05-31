#!/bin/bash
#Basically I'm not fan of aliyun, but aliyum almost provide all of the repositories
#Feel free to modify


set -e

export PATH="$PATH:/usr/local/bin"

#Mirror

MIRROR_REPO=mirrors.aliyun.com
HTTP_MIRROR_REPO=http://mirrors.aliyun.com
NPM_REPO=https://registry.npm.taobao.org
PIP_REPO=${HTTP_MIRROR_REPO}
GEM_REPO=https://ruby.taobao.org/

#Docker mirror 
#Docker is poiting to the daocloud.io, unfortunately you need to register
#if you need to use this mirror, you can put this to true and replace to your register name

DOCKER_MIRROR_ENABLE="false"
DAOCLOUD_ACCOUNT=dummyaccount
DOCKER_MIRROR_REGISTRY=

#Get current user id
CURRENT_USER="$(id -un 2>/dev/null || true)"

#Supper Version Linux
SUPPORT_DISTRO=(debian ubuntu fedora centos)
UBUNTU_CODE=(precise trusty utopic vivid wily xenial)
DEBIAN_CODE=(jessie wheezy)
CENTOS_VER=(6 7)
FEDORA_VER=(20 21 22)

#Fuction
#main
main() {
  
    check_distro
    #change repository
    change_repository
    
    #change node js npm
    if ( check_command_exist npm );then
       change_npm
    else
       echo "[INFO] NPM is not INSTALLED"
    fi
    
    #change pip
    if (check_command_exist pip) || (check_command_exist pip3); then
       change_pip
    else 
       echo "[INFO] pip is not INSTALLED"
    fi

    #change gem
    if (check_command_exist gem);then
       change_gem
    else
       echo "[INFO] gem is not INSTALLED"
    fi
    
    #add go src
    #There is not way to speed up go install/go get....
    if (check_command_exist go);then
       add_go_src
    else
       echo "[INFO] go is not INSTALLED"
    fi
    
    #change docker mirror
    if (check_command_exist docker) && (${DOCKER_MIRROR_ENABLE} = "true"); then
       change_docker_mirror
    else
       echo "[INFO] docker is not CHANGED"
    fi
}
#fuctions

check_command_exist() {
  type "$@" > /dev/null 2>&1
}


check_git_exit() {
    if (check_command_exist git); then
        echo "[INFO]Git found"
    else 
        "You have to install git"
        exit 1
    fi
}

check_user(){
    BASH_C="bash -c"
    if ["${CURRENT_USER}" != "root"]; then
       echo "it will only deploy in your own configuration"
    else
       echo "deploy configuration as root"
    fi
}

check_distro() {
  LSB_DISTRO=""; LSB_VER=""; LSB_CODE=""
  if (check_command_exist lsb_release);then
    LSB_DISTRO="$(lsb_release -si)"
    LSB_VER="$(lsb_release -sr)"
    LSB_CODE="$(lsb_release -sc)"
  fi
  if [ -z "${LSB_DISTRO}" ];then
    if [ -r /etc/lsb-release ];then
      LSB_DISTRO="$(. /etc/lsb-release && echo "${DISTRIB_ID}")"
      LSB_VER="$(. /etc/lsb-release && echo "${DISTRIB_RELEASE}")"
      LSB_CODE="$(. /etc/lsb-release && echo "${DISTRIB_CODENAME}")"
    elif [ -r /etc/os-release ];then
      LSB_DISTRO="$(. /etc/os-release && echo "$ID")"
      LSB_VER="$(. /etc/os-release && echo "$VERSION_ID")"
    elif [ -r /etc/fedora-release ];then
      LSB_DISTRO="fedora"
    elif [ -r /etc/debian_version ];then
      LSB_DISTRO="Debian"
      LSB_VER="$(cat /etc/debian_version)"
    elif [ -r /etc/centos-release ];then
      LSB_DISTRO="CentOS"
      LSB_VER="$(cat /etc/centos-release | cut -d' ' -f3)"
    fi
  fi
  LSB_DISTRO=$(echo "${LSB_DISTRO}" | tr '[:upper:]' '[:lower:]')
  case "${LSB_DISTRO}" in
    ubuntu|debian)
      if [ "${LSB_DISTRO}" == "ubuntu" ]
      then SUPPORT_CODE_LIST="${UBUNTU_CODE[@]}";
      else SUPPORT_CODE_LIST="${DEBIAN_CODE[@]}";
      fi
      if (echo "${SUPPORT_CODE_LIST}" | grep -vqw "${LSB_CODE}");then
        echo "We support ${LSB_DISTRO}( ${SUPPORT_CODE_LIST} ), but current is ${LSB_CODE}(${LSB_VER})"
        exit 202
      fi
    ;;
    centos|fedora)
      CMAJOR=$( echo ${LSB_VER} | cut -d"." -f1 )
      if [  "${LSB_DISTRO}" == "centos" ]
      then SUPPORT_VER_LIST="${CENTOS_VER[@]}";
      else SUPPORT_VER_LIST="${FEDORA_VER[@]}";
      fi
      if (echo "${SUPPORT_VER_LIST}" | grep -qvw "${CMAJOR}");then
        echo "We support ${LSB_DISTRO}( ${SUPPORT_VER_LIST} ), but current is ${LSB_VER}"
        exit 202
      fi
    ;;
    *) if [ ! -z ${LSB_DISTRO} ];then echo -e -n "\nCurrent OS is '${LSB_DISTRO} ${LSB_VER}(${LSB_CODE})'";
       else echo -e -n "\nCan not detect OS type"; fi
       exit 1
    ;;
  esac
  #echo -n "."
  
}

change_repository(){
#    check_user

    if (check_command_exist sudo);then
      BASH_C="sudo"
    else
      echo "You have to run this with root"
    fi
    
    ##Debug
    #echo "${LSB_DISTRO}"
    
    case "${LSB_DISTRO}" in
      ubuntu|debian)

      ${BASH_C} sed -i "s/http:\/\/.*.archive.${LSB_DISTRO}.com/http:\/\/${MIRROR_REPO}/g" /etc/apt/sources.list
      echo "[INFO] Your ${LSB_DISTRO} has changed to ${MIRROR_REPO}"
      grep "^deb" /etc/apt/sources.list
      ${BASH_C} apt-get update -qq
     #if [ "${LSB_DISTRO}" == "ubuntu" ]
      #then
      #${BASH_C} echo 'deb http://${MIRROR_REPO}/${LSB_DISTRO}/${LSB_DISTRO} ${LSB_CODE} multiverse' >> /etc/apt/sources.list
      #${BASH_C} echo 'deb-src http://${MIRROR_REPO}/${LSB_DISTRO}/${LSB_DISTRO}  ${LSB_CODE} multiverse' >> /etc/apt/sources.list
      #fi
      ;;
      centos)
      ${BASH_C} rpm --import ${HTTP_MIRROR_REPO}/centos/RPM-GPG-KEY-CentOS-${LSB_VER}
      ${BASH_C} wget -O /etc/yum.repos.d/CentOS-Base.repo ${HTTP_MIRROR_REPO}/repo/CentOS-${LSB_VER}.repo
      ${BASH_C} wget -qO /etc/yum.repos.d/epel.repo ${HTTP_MIRROR_REPO}/repo/epel-${LSB_VER}.repo
      ${BASH_C} yum clean metadata
      ${BASH_C} yum makecache
      ;;
      fedora)
      ${BASH_C} wget -O /etc/yum.repos.d/Fedora-Base.repo ${HTTP_MIRROR_REPO}/repo/fedora.repo
      ${BASH_C} wget -qO /etc/yum.release/Fedora-Update.repo ${HTTP_MIRROR_REPO}/repo/fedora-updates.repo
      ;;
      *)
      echo "Your ${LSB_DISTRO} is not in support list"
      exit 1
      ;;
     esac
}

add_go_src() {
    set -u 
    
    check_git_exit
    
    if [ ! -z ${GOPATH}]; then
      mkdir -p ${GOPATH}/src/golang.org/x/
      git clone git@github.com:golang/tools.git ${GOPATH}/src/golang.org/x/
    else 
      echo "Please setup \$GOPATH"
    fi

    set +u
}

change_npm() {
    ${BASH_C} npm config set registry ${NPM_REPO} > /dev/null 2>&1
    echo "[INFO] NPM registry changed to ${NPM_REPO}"

}

change_pip() {
    ##check .pip if existing
    set -u
    PIP_DIR=${HOME}/.pip
    PIP_CONF=${PIP_DIR}/pip.conf

    if [ ! -d ${PIP_DIR} ]; then
        mkdir $PIP_DIR
    else
        echo "[WARNING] ${PIP_DIR} is existing"
    fi

    ##debug
    #echo "${PIP_DIR}"
    #echo "${PIP_CONF}"
    #echo "${BASH_C}"
    #echo "${PIP_REPO}"

    #TODO add user
    cat << EOF > ${PIP_CONF}
[global]
index-url = ${PIP_REPO}/pypi/simple/
EOF
    
    echo "[INFO] PIP repository changed to ${PIP_REPO}"
    set +u 
}

change_gem() {
    gem sources --add ${GEM_REPO} --remove https://rubygems.org/ > /dev/null 2>&1
    echo "[INFO] GEM repository changed to ${GEM_REPO}"

}

change_docker_mirror() {
     if (check_command_exist sudo);then
      BASH_C="sudo -E bash -c"
    else
      echo "You have to run this with root"
    fi

    case ${LSB_DISTRO} in
    ubuntu|debian)
      ${BASH_C} echo "DOCKER_OPTS=\"\$DOCKER_OPTS --registry-mirror=http://${DAOCLOUD_ACCOUNT}.m.daocloud.io\"" >> /etc/default/docker
      ;;
    centos|fedora)
      ${BASH_C} sudo sed -i "s|OPTIONS=|OPTIONS=--registry-mirror=http://${DAOCLOUD_ACCOUNT}.m.daocloud.io |g" /etc/sysconfig/docker
      ;;
     *)
      echo "Your ${LSB_DISTRO} is not supported"
      ;;
     esac
     ${BASH_C} service docker restart
}


#Run main function
main
