#!/bin/bash

set -e

export PATH="$PATH:/usr/local/bin"

#Mirror
MIRROR_REPO=mirrors.aliyun.com

#Get current user id
CURRENT_USER="$(id -un 2>/dev/null || true)"

#Supper Version Linux
SUPPORT_DISTRO=(debian ubuntu fedora centos)
UBUNTU_CODE=(trusty utopic vivid wily xenial)
DEBIAN_CODE=(jessie wheezy)
CENTOS_VER=(6 7)
FEDORA_VER=(20 21 22)

#Fuction
#main

#fuctions

check_command_exist() {
  type "$@" > /dev/null 2>&1
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
  if (command_exist lsb_release);then
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
  echo -n "."
  
}

change_repository{
    if (check_command_exist sudo);then
      BASH_C="sudo -E bash -c"
    else
      echo "You have to run this with root"
    fi
    
    case "${LSB_DISTRO}" in
      ubuntu|debian)
      ${BASH_C} sed -i "s/archive.${LSB_DISTRO}.com/${MIRROR_REPO}/g" /etc/apt/sources.list
     #if [ "${LSB_DISTRO}" == "ubuntu" ]
      #then
      #${BASH_C} echo 'deb http://${MIRROR_REPO}/${LSB_DISTRO}/${LSB_DISTRO} ${LSB_CODE} multiverse' >> /etc/apt/sources.list
      #${BASH_C} echo 'deb-src http://${MIRROR_REPO}/${LSB_DISTRO}/${LSB_DISTRO}  ${LSB_CODE} multiverse' >> /etc/apt/sources.list
      #fi
      ;;
      
}

