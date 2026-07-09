#!/bin/sh


ROUTER=${1:-steam-deck-plugin}
MODEL=${2}

INSTALL_DIR=""
PLUGIN_EXE="uuplugin"
RUNNING_DIR="/tmp/uu"
MONITOR_FILENAME="uuplugin_monitor.sh"

STEAM_DECK_PLUGIN="steam-deck-plugin"

get_steam_deck_install_dir() {
    local sd_install_dir="/home/deck"
    if [ -d ${sd_install_dir} ] ; then
        echo "${sd_install_dir}/uu/"
        return 0
    fi

    sd_install_dir="/home/bazzite"
    if [ -d ${sd_install_dir} ] ; then
        chmod a+xr ${sd_install_dir}
        echo "${sd_install_dir}/uu/"
        return 0
    fi

    sd_install_dir="$(pwd)"
    install_dir_prefix=${str:0:6}
    if [ x"${install_dir_prefix}" = x"/home/" ] ; then
        chmod a+xr ${sd_install_dir}
        echo "${sd_install_dir}/uu/"
        return 0
    fi

    sd_install_dir="/home/uu"
    chmod a+xr ${sd_install_dir}
    echo "${sd_install_dir}/uu/"
    return 0
}

init_param() {
    case ${ROUTER} in
    ${STEAM_DECK_PLUGIN})
        INSTALL_DIR=$(get_steam_deck_install_dir)
        return 0
        ;;
    *)
        return 1
        ;;
    esac
}

kill_uuplugin() {
    # 按进程名强制终止 uuplugin
    local TIMES="1 2 3"
    for i in ${TIMES};do
        pgrep -x "${PLUGIN_EXE}" >/dev/null 2>&1 || return 0
        sleep 1
    done

    echo "pkill -9 ${PLUGIN_EXE}"
    pkill -9 -x "${PLUGIN_EXE}"
}

stop_uuplugin() {
    # 按进程名优雅终止 uuplugin
    echo "pkill -SIGINT ${PLUGIN_EXE}"
    pkill -SIGINT -x "${PLUGIN_EXE}"

    kill_uuplugin
}

stop_monitor() {
    # 按进程名终止监控脚本
    echo "pkill -9 ${MONITOR_FILENAME}"
    pkill -9 -f "${MONITOR_FILENAME}"
}

steam_deck_plugin_clean_up() {
    local uuplugin_service="/etc/systemd/system/uuplugin.service"
    if [ -d "${INSTALL_DIR}" ];then
        rm -r "${INSTALL_DIR}"/* 1>/dev/null 2>&1
    fi

    # clean up uuplugin
    if [ -d "${RUNNING_DIR}" ];then
        rm -r "${RUNNING_DIR}"/* 1>/dev/null 2>&1
    fi

    systemctl disable uuplugin
    systemctl stop uuplugin
    rm ${uuplugin_service}

    stop_uuplugin
    stop_monitor
    return 0
}

clean_up() {
    case ${ROUTER} in
        ${STEAM_DECK_PLUGIN})
            steam_deck_plugin_clean_up
            return $?
            ;;
        *)
            return 1
            ;;
    esac
}

init_param
[ "$?" != 0 ] && return 1

clean_up
