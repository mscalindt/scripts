#!/bin/sh
# shellcheck disable=SC2086

: <<'notice'
 * Script information:
 *   Copy kernel .config as defconfig.
 *
 * Usage:
 *   KL_DIR: [essential] [path]
 *   Specify kernel directory with .config file.
 *
 *   KL_ARCH: [essential] [string]
 *   Specify arch.
 *
 *   DCONF: [essential] [string]
 *   Specify name for the defconfig.
 *
 *   VENDOR_DCONF: [toggle] [0]
 *   0 = .config will be copied to arch/<arch>/configs
 *   1 = .config will be copied to arch/<arch>/configs/vendor
 *
 * SPDX-License-Identifier: GPL-3.0
 *
 * Copyright (C) 2020-2021 Dimitar Yurukov <mscalindt@protonmail.com>
 *
notice

variables() {
    KL_DIR=""
    KL_ARCH=
    DCONF=

    VENDOR_DCONF=0
}

helpers() {
    script_death() {
        hlps_cmd=$(printf "%s" "$1")
        hlps_cmd_rc=$(printf "%d" "$2")
        hlps_line=$(printf "%d" "$3")
        hlps_info=$(printf "%s" "$4")
        hlps_exec_func=$(printf "%s" "$5")
        hlps_exec_func0=$(printf "%s" "$6")

        echo

        printf "%b" "\033[1;31m"
        echo "Script failed!"
        printf "%b" "\033[1;37m"

        if [ -n "$hlps_cmd" ]; then
            printf "Command: %s" "${hlps_cmd}"
            echo
        fi

        if [ -n "$hlps_cmd_rc" ] && [ $hlps_cmd_rc -ne 0 ]; then
            printf "Exit code: %d" "${hlps_cmd_rc}"
            echo
        fi

        if [ -n "$hlps_line" ] && [ $hlps_line -ne 0 ]; then
            printf "Line number: %d" "${hlps_line}"
            echo
        fi

        if [ -n "$hlps_info" ]; then
            printf "Additional info: %s" "${hlps_info}"
            echo
        fi

        printf "%b" "\033[0m"

        if [ -n "$hlps_exec_func" ]; then
            ${hlps_exec_func};
        fi

        if [ -n "$hlps_exec_func0" ]; then
            ${hlps_exec_func0};
        fi

        echo

        if [ -n "$hlps_cmd_rc" ] && [ $hlps_cmd_rc -ne 0 ]; then
            exit $hlps_cmd_rc
        else
            exit 1
        fi
    }
}

probe_vars() {
    if [ -z $KL_DIR ]; then
        script_death "" "" "" "KL_DIR is empty" "" ""
    fi

    if [ -z $KL_ARCH ]; then
        script_death "" "" "" "KL_ARCH is empty" "" ""
    fi

    if [ -z $DCONF ]; then
        script_death "" "" "" "DCONF is empty" "" ""
    fi
}

copy_conf() {
    copy_conf_work() {
        cp_conf_loc="$KL_DIR"/.config
        cp_dest_loc="$KL_DIR"/arch/$KL_ARCH/configs/$DCONF

        if [ $VENDOR_DCONF -eq 1 ]; then
            cp_dest_loc="$KL_DIR"/arch/$KL_ARCH/configs/vendor/$DCONF
        fi
    }

    copy_conf_exec() {
        cp "$cp_conf_loc" "$cp_dest_loc"
        cp_rc=$(printf "%d" "$?")

        if [ $cp_rc -ne 0 ]; then
            script_death "cp" "${cp_rc}" "" "File copy failed" "" ""
        fi
    }

    copy_conf_work;
    copy_conf_exec;
}

variables;
helpers;
probe_vars;
copy_conf;
