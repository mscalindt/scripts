#!/bin/sh
# shellcheck disable=SC2086

: <<'notice'
 * Script information:
 *   Increment number in filenames. Supports whitespace. As always, do a backup
 *   of the files before running the script.
 *
 * Usage:
 *   DIR: [essential] [path]
 *   Specify the directory in which files with number in their filename exist.
 *
 *   INCREMENT: [value] [X]
 *   Specify by how much to increment. If left empty, default (1) is used.
 *
 * SPDX-License-Identifier: GPL-3.0
 *
 * Copyright (C) 2020-2021 Dimitar Yurukov <mscalindt@protonmail.com>
 *
notice

variables() {
    DIR=""
    INCREMENT=
}

helpers() {
    increment_num_str() {
        hlps_str="$1"

        for num in $(printf "%s" "${hlps_str}" | grep -Eo '[0-9]+'); do
            h_old_num=$(printf "%d" "${num}")
            h_new_num=$((num + INCREMENT))
        done

        h_new_str=$(printf "%s" "${hlps_str}" | sed "s/$h_old_num/$h_new_num/")

        printf "%s" "${h_new_str}"
    }

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
    if [ -z $DIR ]; then
        script_death "" "" "" "DIR is empty" "" ""
    fi
}

increment() {
    increment_work() {
        increment_work_vars() {
            tmp_dir_loc=$(cd "$DIR"/.. && printf "%s" "$PWD")
            tmp_dir="$tmp_dir_loc"/TMPincrement
            
            if [ -z $INCREMENT ]; then
                INCREMENT=1
            fi
        }

        increment_work_cmds() {
            if [ -d "$tmp_dir" ]; then
                rm -rf "$tmp_dir"
            fi

            mkdir "$tmp_dir"
        }

        increment_work_vars;
        increment_work_cmds;
    }

    increment_exec() {
        files="$DIR/*"
        files_tmp="$tmp_dir/*"

        for file in $files; do
            cur_filename=$(basename "$file")
            cur_loc=$(printf "%s/%s" "${DIR}" "${cur_filename}")
            new_filename=$(increment_num_str "$cur_filename")
            new_loc=$(printf "%s/%s" "${tmp_dir}" "${new_filename}")

            mv -v "$cur_loc" "$new_loc"
        done

        for file in $files_tmp; do
            cur_filename=$(basename "$file")
            cur_loc=$(printf "%s/%s" "${tmp_dir}" "${cur_filename}")
            new_loc=$(printf "%s/%s" "${DIR}" "${cur_filename}")

            mv -v "$cur_loc" "$new_loc"
        done
    }

    increment_cleanup() {
        rm -rf "$tmp_dir"
    }

    increment_work;
    increment_exec;
    increment_cleanup;
}

variables;
helpers;
probe_vars;
increment;
