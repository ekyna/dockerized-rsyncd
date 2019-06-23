#!/bin/bash

cd "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [[ ! -f './.env' ]]
then
    printf "\e[31mEnv file not found\e[0m\n"
    exit 1;
fi

source ./.env

if [[ -z ${COMPOSE_PROJECT_NAME+x} ]]; then printf "\e[31mThe 'COMPOSE_PROJECT_NAME' variable is not defined.\e[0m\n"; exit 1; fi
if [[ -z ${READ_ONLY+x} ]]; then printf "\e[31mThe 'READ_ONLY' variable is not defined.\e[0m\n"; exit 1; fi
if [[ -z ${CHROOT+x} ]]; then printf "\e[31mThe 'CHROOT' variable is not defined.\e[0m\n"; exit 1; fi
if [[ -z ${HOSTS_ALLOW+x} ]]; then printf "\e[31mThe 'HOSTS_ALLOW' variable is not defined.\e[0m\n"; exit 1; fi
if [[ -z ${USER_ID+x} ]]; then printf "\e[31mThe 'USER_ID' variable is not defined.\e[0m\n"; exit 1; fi
if [[ -z ${GROUP_ID+x} ]]; then printf "\e[31mThe 'GROUP_ID' variable is not defined.\e[0m\n"; exit 1; fi
if [[ -z ${RSYNC_PORT+x} ]]; then printf "\e[31mThe 'RSYNC_PORT' variable is not defined.\e[0m\n"; exit 1; fi
if [[ -z ${SSH_PORT+x} ]]; then printf "\e[31mThe 'SSH_PORT' variable is not defined.\e[0m\n"; exit 1; fi

LOG_PATH="./log/docker.log"
echo "" > ${LOG_PATH}

Title() {
    printf "\n\e[1;46m ----- $1 ----- \e[0m\n"
}

Success() {
    printf "\e[32m$1\e[0m\n"
}

Error() {
    printf "\e[31m$1\e[0m\n"
}

Warning() {
    printf "\e[31;43m$1\e[0m\n"
}

Comment() {
    printf "\e[36m$1\e[0m\n"
}

Help() {
    printf "\e[2m$1\e[0m\n"
}

Ln() {
    printf "\n"
}

DoneOrError() {
    if [[ $1 -eq 0 ]]
    then
        Success 'done'
    else
        Error 'error'
        exit 1
    fi
}

Confirm () {
    Ln

    choice=""
    while [[ "$choice" != "n" ]] && [[ "$choice" != "y" ]]
    do
        printf "Do you want to continue ? (N/Y)"
        read choice
        choice=$(echo ${choice} | tr '[:upper:]' '[:lower:]')
    done

    if [[ "$choice" = "n" ]]; then
        Warning "Abort by user"
        exit 0
    fi

    Ln
}

VolumeExists() {
    if [[ "$(docker volume ls --format '{{.Name}}' | grep $1\$)" ]]
    then
        return 0
    fi
    return 1
}

VolumeCreate() {
    printf "Creating volume \e[1;33m$1\e[0m ... "
    if ! VolumeExists $1
    then
        docker volume create --name $1 >> ${LOG_PATH} 2>&1
        if [[ $? -eq 0 ]]
        then
            Success "created"
        else
            Error "error"
            exit 1
        fi
    else
        Comment "exists"
    fi
}

VolumeRemove() {
    printf "Removing volume \e[1;33m$1\e[0m ... "
    if VolumeExists $1
    then
        docker volume rm $1 >> ${LOG_PATH} 2>&1
        if [[ $? -eq 0 ]]
        then
            Success "removed"
        else
            Error "error"
            exit 1
        fi
    else
        Comment "unknown"
    fi
}

IsUpAndRunning() {
    if [[ "$(docker ps --format '{{.Names}}' | grep ${COMPOSE_PROJECT_NAME}_$1\$)" ]]
    then
        return 0
    fi
    return 1
}

ComposeUp() {
    printf "Composing \e[1;33mUp\e[0m ... "
    docker-compose -f compose.yml up -d --build >> ${LOG_PATH} 2>&1
    DoneOrError $?
}

ComposeDown() {
    printf "Composing \e[1;33mDown\e[0m ... "
    docker-compose -f compose.yml down -v --remove-orphans >> ${LOG_PATH} 2>&1
    DoneOrError $?
}

CreateVolumes() {
    VolumeCreate "${COMPOSE_PROJECT_NAME}_ssh"
    VolumeCreate "${COMPOSE_PROJECT_NAME}_data"
}

RemoveVolumes() {
    VolumeRemove "${COMPOSE_PROJECT_NAME}_ssh"
    VolumeRemove "${COMPOSE_PROJECT_NAME}_data"
}

case $1 in
    # -------------- UP --------------
    up)
        CreateVolumes

        ComposeUp
    ;;
    # ------------- DOWN -------------
    down)
        ComposeDown
    ;;
    # ------------- DOWN -------------
    clear)
        Title "Clearing stack"
        Confirm

        ComposeDown

        RemoveVolumes
    ;;
    # ------------- DOWN -------------
    ssh)
        if [[ $2 == 'allow' ]]
        then
            printf "Allowing \e[1;33mssh password\e[0m ... "
            export MSYS_NO_PATHCONV=1 && \
                docker exec ${COMPOSE_PROJECT_NAME}_rsync bash -c \
                    "/entrypoint.sh ssh-allow" >> ${LOG_PATH} 2>&1
        elif [[ $2 == 'deny' ]]
        then
            printf "Denying \e[1;33mssh password\e[0m ... "
            export MSYS_NO_PATHCONV=1 && \
                docker exec ${COMPOSE_PROJECT_NAME}_rsync bash -c \
                    "/entrypoint.sh ssh-deny" >> ${LOG_PATH} 2>&1
        else
            Help "Usage: ./manage.sh ssh [allow|deny]"
            exit 1
        fi

        DoneOrError $?
    ;;
    # ------------- HELP -------------
    *)
        Help "Usage: ./manage.sh [action] [options]

  \e[0mup\e[2m   Create network and volumes and start containers.
  \e[0mdown\e[2m Stop containers."
    ;;
esac
