#!/bin/sh
# shellcheck disable=SC2012
# shellcheck disable=SC2086
# shellcheck disable=SC2164

: <<'notice'
 *
 * Script information:
 *   Advanced universal script for Linux kernel building.
 *
 * Usage:
 *   KL_DIR: [essential] [path]
 *   Specify the kernel directory.
 *
 *   KL_DCONF: [essential] [string]
 *   Specify the defconfig to use.
 *
 *   KL_ARCH: [essential] [string]
 *   Specify the architecture to build for.
 *
 *   TC_DIR: [path]
 *   Specify directory that contains a cross compiler. If left empty, only the
 *   host compiler will be used.
 *
 *   ZP_DIR: [path]
 *   Specify a directory to which the image has to be sent. It will be zipped
 *   alongside the directory's files.
 *
 *   ZP_KL_NAME: [essential if ZP_DIR] [string]
 *   Specify kernel name string to append to the filename of the zip.
 *
 *   ZP_KL_VERSION: [string]
 *   Specify version string to append to the filename of the zip.
 *
 *   ZP_KL_DEVICE: [string]
 *   Specify device string to append to the filename of the zip.
 *
 *   ZP_APPEND_DATE: [toggle] [0]
 *   0 = will not append YYYY/MM/DD date string to the filename of the zip.
 *   1 = will append YYYY/MM/DD date string to the filename of the zip.
 *
 *   ZP_COPY_DTB_IMG: [toggle] [0]
 *   0 = will copy the kernel image.
 *   1 = will copy the kernel DTB image (specific to arm64). Only enable this
 *       if you are sure there is DTB image to copy, otherwise you will be left
 *       without a kernel image.
 *
 *   BUILD_OUTPUT_DIR: [path]
 *   Specify custom object build directory. If left empty, a directory will be
 *   created on the same path level as the kernel directory.
 *
 *   BUILD_USER: [string]
 *   The string entered here will be shown for kernel build user.
 *
 *   BUILD_HOST: [string]
 *   The string entered here will be shown for kernel build host.
 *
 *   LOCALVERSION: [string]
 *   Append a string to the kernel release. For example, a string such as "-wow"
 *   will set the kernel release version from "5.8.7" to "5.8.7-wow", assuming
 *   no external modifications take place.
 *
 *   CORES: [value] [X]
 *   Specify how many CPU cores to use. If left empty, all cores will be used.
 *
 *   CCACHE: [toggle] [0]
 *   0 = 'ccache' will not be used.
 *   1 = 'ccache' will be used.
 *
 *   CLEAN_BUILD: [toggle] [0]
 *   0 = the script will not perform any kind of build cleaning.
 *   1 = the script will delete output files from previous build and/or run
 *       'make clean && make mrproper' where appropriate.
 *
 *   CLANG: [toggle] [0]
 *   0 = will use GCC.
 *   1 = will use Clang instead of GCC to compile the kernel. For now, only x86
 *       kernel architecture is supported.
 *
 *   INSTALL: [toggle] [0]
 *   0 = will not install the kernel.
 *   1 = will copy the kernel and update boot configuration. Only x86-64/amd64
 *       and GRUB2 is supported. The script does NOT generate initramfs and does
 *       NOT handle kernel headers; take appropriate action for these after the
 *       script is done. Microcode, if any found in /boot, will be loaded by the
 *       new boot entry.
 *
 *   SYNC_KL: [toggle] [0]
 *   0 = no git commands will be executed on the kernel directory.
 *   1 = git reset/clean/pull will be executed on the kernel directory to bring
 *       the local state identical to the remote one. This works only on local
 *       repo with history / non-shallow repo. Careful though, the commands will
 *       wipe all local changes and commits!
 *
 *   SYNC_TC: [toggle] [0]
 *   0 = no git commands will be executed on the toolchain directory.
 *   1 = git reset/clean/pull will be executed on the toolchain directory to
 *       bring the local state identical to the remote one. This works only on
 *       local repo with history / non-shallow repo. Careful though, the
 *       commands will wipe all local changes and commits!
 *
 *   SYNC_ZP: [toggle] [0]
 *   0 = no git commands will be executed on the zipper directory.
 *   1 = git reset/clean/pull will be executed on the zipper directory to bring
 *       the local state identical to the remote one. This works only on local
 *       repo with history / non-shallow repo. Careful though, the commands will
 *       wipe all local changes and commits!
 *
 *   KL_REPO: [link]
 *   Specify HTTPS git link to clone if the kernel directory is missing. The
 *   clone will be shallow, i.e. without commit history. All submodules (if any)
 *   will also be shallow cloned.
 *
 *   KL_BRANCH: [string]
 *   Specify which kernel branch to clone. If left empty, the default branch
 *   will be cloned.
 *
 *   TC_REPO: [link]
 *   Specify HTTPS git link to clone if the toolchain directory is missing. The
 *   clone will be shallow, i.e. without commit history. All submodules (if any)
 *   will also be shallow cloned.
 *
 *   TC_BRANCH: [string]
 *   Specify which toolchain branch to clone. If left empty, the default branch
 *   will be cloned.
 *
 *   ZP_REPO: [link]
 *   Specify HTTPS git link to clone if the zipper directory is missing. The
 *   clone will be shallow, i.e. without commit history. All submodules (if any)
 *   will also be shallow cloned.
 *
 *   ZP_BRANCH: [string]
 *   Specify which zipper branch to clone. If left empty, the default branch
 *   will be cloned.
 *
 * SPDX-License-Identifier: GPL-3.0
 *
 * Copyright (C) 2020-2021 Dimitar Yurukov <mscalindt@protonmail.com>
 *
notice

variables() {
    KL_DIR=""
    KL_DCONF=
    KL_ARCH=

    TC_DIR=""
    ZP_DIR=""
    ZP_KL_NAME=
    ZP_KL_VERSION=
    ZP_KL_DEVICE=
    ZP_APPEND_DATE=0
    ZP_COPY_DTB_IMG=0
    BUILD_OUTPUT_DIR=""

    BUILD_USER=
    BUILD_HOST=
    LOCALVERSION=

    CORES=
    CCACHE=0
    CLEAN_BUILD=0
    CLANG=0
    INSTALL=0

    SYNC_KL=0
    SYNC_TC=0
    SYNC_ZP=0

    KL_REPO=
    KL_BRANCH=
    TC_REPO=
    TC_BRANCH=
    ZP_REPO=
    ZP_BRANCH=
}

helpers() {
    cmd_available() {
        hlps_cmd=$(printf "%s" "$1")

        if command -v "$hlps_cmd" > /dev/null 2>&1; then
            return 0
        else
            return 127
        fi
    }

    convert_binary_bytes() {
        hlps_bytes=$(printf "%s" "$1")

        if [ $hlps_bytes -le 1024 ]; then
            hlps_unit=B
            printf "%d %s" "${hlps_bytes}" "${hlps_unit}"
        elif [ $hlps_bytes -le 1048576 ]; then
            hlps_unit=KiB
            hlps_delim=$((hlps_bytes % 1024 * 1000 / 1024))
            hlps_units=$((hlps_bytes / 1024))
            hlps_float=$(printf "%d.%d" "${hlps_units}" "${hlps_delim}")
            printf "%.3f %s" "${hlps_float}" "${hlps_unit}"
        elif [ $hlps_bytes -le 1073741824 ]; then
            hlps_unit=MiB
            hlps_delim=$((hlps_bytes % 1048576 * 1000 / 1048576))
            hlps_units=$((hlps_bytes / 1048576))
            hlps_float=$(printf "%d.%d" "${hlps_units}" "${hlps_delim}")
            printf "%.3f %s" "${hlps_float}" "${hlps_unit}"
        fi
    }

    convert_metric_bytes() {
        hlps_bytes=$(printf "%s" "$1")

        if [ $hlps_bytes -le 1000 ]; then
            hlps_unit=B
            printf "%d %s" "${hlps_bytes}" "${hlps_unit}"
        elif [ $hlps_bytes -le 1000000 ]; then
            hlps_unit=KB
            hlps_delim=$((hlps_bytes % 1000 * 1000 / 1000))
            hlps_units=$((hlps_bytes / 1000))
            hlps_float=$(printf "%d.%d" "${hlps_units}" "${hlps_delim}")
            printf "%.3f %s" "${hlps_float}" "${hlps_unit}"
        elif [ $hlps_bytes -le 1000000000 ]; then
            hlps_unit=MB
            hlps_delim=$((hlps_bytes % 1000000 * 1000 / 1000000))
            hlps_units=$((hlps_bytes / 1000000))
            hlps_float=$(printf "%d.%d" "${hlps_units}" "${hlps_delim}")
            printf "%.3f %s" "${hlps_float}" "${hlps_unit}"
        fi
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

    text_clr() {
        hlps_clr=$(printf "%s" "$1")

        if [ $hlps_clr = def ]; then
            printf "%b" "\033[0m"
        elif [ $hlps_clr = black ]; then
            printf "%b" "\033[1;30m"
        elif [ $hlps_clr = red ]; then
            printf "%b" "\033[1;31m"
        elif [ $hlps_clr = green ]; then
            printf "%b" "\033[1;32m"
        elif [ $hlps_clr = yellow ]; then
            printf "%b" "\033[1;33m"
        elif [ $hlps_clr = blue ]; then
            printf "%b" "\033[1;34m"
        elif [ $hlps_clr = purple ]; then
            printf "%b" "\033[1;35m"
        elif [ $hlps_clr = cyan ]; then
            printf "%b" "\033[1;36m"
        elif [ $hlps_clr = white ]; then
            printf "%b" "\033[1;37m"
        fi
    }
}

probe_vars() {
    if [ -z $KL_DIR ]; then
        script_death "" "" "" "KL_DIR is empty" "" ""
    fi

    if [ -z $KL_DCONF ]; then
        script_death "" "" "" "KL_DCONF is empty" "" ""
    fi

    if [ -z $KL_ARCH ]; then
        script_death "" "" "" "KL_ARCH is empty" "" ""
    fi

    if [ -n "$ZP_DIR" ]; then
        if [ -z $ZP_KL_NAME ]; then
            script_death "" "" "" "ZP_KL_NAME is empty" "" ""
        fi
    fi
}

env_check() {
    env_check_root() {
        euid=$(id -u)

        if [ $euid -eq 0 ]; then
            script_death "" "" "" "EUID is 0 (root)" "" ""
        fi
    }

    env_check_root;
}

pkg_check() {
    pkg_check_gcc() {
        if [ $CLANG -eq 0 ]; then
            if ! cmd_available gcc; then
                script_death "gcc" "127" "" "'gcc' is not installed" "" ""
            fi
        fi
    }

    pkg_check_clang() {
        if [ $CLANG -eq 1 ]; then
            if ! cmd_available clang; then
                script_death "clang" "127" "" "'clang' is not installed" "" ""
            fi
        fi
    }

    pkg_check_coreutils() {
        if ! cmd_available nproc; then
            script_death "nproc" "127" "" "'coreutils' is not installed" "" ""
        fi
    }

    pkg_check_ccache() {
        if [ $CCACHE -eq 1 ]; then
            if ! cmd_available ccache; then
                script_death "ccache" "127" "" "'ccache' is not installed" "" ""
            fi
        fi
    }

    pkg_check_git() {
        if [ -n "$KL_REPO" ] || [ -n "$TC_REPO" ] || \
           [ -n "$ZP_REPO" ] || [ $SYNC_KL -eq 1 ] || \
           [ $SYNC_TC -eq 1 ] || [ $SYNC_ZP -eq 1 ] || \
           [ -n "$ZP_DIR" ]; then
            if ! cmd_available git; then
                script_death "git" "127" "" "'git' is not installed" "" ""
            fi
        fi
    }

    pkg_check_zip() {
        if [ -n "$ZP_DIR" ]; then
            if ! cmd_available zip; then
                script_death "zip" "127" "" "'zip' is not installed" "" ""
            fi
        fi
    }

    pkg_check_gcc;
    pkg_check_clang;
    pkg_check_coreutils;
    pkg_check_ccache;
    pkg_check_git;
    pkg_check_zip;
}

clone() {
    clone_work() {
        clone_work_kernel() {
            kl_clone_cmd=$KL_REPO
            kl_clone_cmd="${kl_clone_cmd} ${KL_DIR}"
            kl_clone_cmd="${kl_clone_cmd} --depth 1"
            kl_clone_cmd="${kl_clone_cmd} --shallow-submodules"
            kl_clone_cmd="${kl_clone_cmd} --recursive"

            if [ -n "$KL_BRANCH" ]; then
                kl_clone_cmd="${kl_clone_cmd} --branch ${KL_BRANCH}"
            fi
        }

        clone_work_toolchain() {
            tc_clone_cmd=$TC_REPO
            tc_clone_cmd="${tc_clone_cmd} ${TC_DIR}"
            tc_clone_cmd="${tc_clone_cmd} --depth 1"
            tc_clone_cmd="${tc_clone_cmd} --shallow-submodules"
            tc_clone_cmd="${tc_clone_cmd} --recursive"

            if [ -n "$TC_BRANCH" ]; then
                tc_clone_cmd="${tc_clone_cmd} --branch ${TC_BRANCH}"
            fi
        }

        clone_work_zipper() {
            zp_clone_cmd=$ZP_REPO
            zp_clone_cmd="${zp_clone_cmd} ${ZP_DIR}"
            zp_clone_cmd="${zp_clone_cmd} --depth 1"
            zp_clone_cmd="${zp_clone_cmd} --shallow-submodules"
            zp_clone_cmd="${zp_clone_cmd} --recursive"

            if [ -n "$ZP_BRANCH" ]; then
                zp_clone_cmd="${zp_clone_cmd} --branch ${ZP_BRANCH}"
            fi
        }

        if [ -n "$KL_REPO" ]; then
            clone_work_kernel;
        fi

        if [ -n "$TC_REPO" ]; then
            clone_work_toolchain;
        fi

        if [ -n "$ZP_REPO" ]; then
            clone_work_zipper;
        fi
    }

    clone_kernel() {
        if [ ! -d "$KL_DIR" ]; then
            git clone ${kl_clone_cmd}
            git_rc=$(printf "%d" "$?")
        fi

        if [ ! -d "$KL_DIR" ]; then
            script_death "git" "${git_rc}" "" "Kernel clone failed" "" ""
        fi
    }

    clone_toolchain() {
        if [ ! -d "$TC_DIR" ]; then
            git clone ${tc_clone_cmd}
            git_rc=$(printf "%d" "$?")
        fi

        if [ ! -d "$TC_DIR" ]; then
            script_death "git" "${git_rc}" "" "Toolchain clone failed" "" ""
        fi
    }

    clone_zipper() {
        if [ ! -d "$ZP_DIR" ]; then
            git clone ${zp_clone_cmd}
            git_rc=$(printf "%d" "$?")
        fi

        if [ ! -d "$ZP_DIR" ]; then
            script_death "git" "${git_rc}" "" "Zipper clone failed" "" ""
        fi
    }

    clone_work;

    if [ -n "$KL_REPO" ]; then
        clone_kernel;
    fi

    if [ -n "$TC_REPO" ]; then
        clone_toolchain;
    fi

    if [ -n "$ZP_REPO" ]; then
        clone_zipper;
    fi
}

sync() {
    sync_kernel() {
        cd "$KL_DIR"
        cd_rc=$(printf "%d" "$?")

        if [ $cd_rc -ne 0 ]; then
            script_death "cd" "${cd_rc}" "$LINENO" "" "" ""
        fi

        git reset HEAD .
        git clean -fd
        git reset --hard "@{upstream}"
        git pull --rebase=true
    }

    sync_toolchain() {
        cd "$TC_DIR"
        cd_rc=$(printf "%d" "$?")

        if [ $cd_rc -ne 0 ]; then
            script_death "cd" "${cd_rc}" "$LINENO" "" "" ""
        fi

        git reset HEAD .
        git clean -fd
        git reset --hard "@{upstream}"
        git pull --rebase=true
    }

    sync_zipper() {
        cd "$ZP_DIR"
        cd_rc=$(printf "%d" "$?")

        if [ $cd_rc -ne 0 ]; then
            script_death "cd" "${cd_rc}" "$LINENO" "" "" ""
        fi

        git reset HEAD .
        git clean -fd
        git reset --hard "@{upstream}"
        git pull --rebase=true
    }

    if [ $SYNC_KL -eq 1 ]; then
        sync_kernel;
    fi

    if [ $SYNC_TC -eq 1 ]; then
        sync_toolchain;
    fi

    if [ $SYNC_ZP -eq 1 ]; then
        sync_zipper;
    fi
}

build_kernel() {
    build_kernel_work() {
        build_kernel_work_vars() {
            kl_out_dir="${KL_DIR}"out
            kl_conf="$KL_DIR"/arch/$KL_ARCH/configs/$KL_DCONF
            kl_vendor_conf="$KL_DIR"/arch/$KL_ARCH/configs/vendor/$KL_DCONF
            kl_conf_make=$KL_DCONF
            kl_vendor_conf_make=vendor/$KL_DCONF
            kl_conf_obj="$KL_DIR"/scripts/kconfig/conf.o
            cpu_avl_cores=$(nproc --all)
            gcc_loc=$(command -v gcc)
            clang_loc=$(command -v clang)
            ccache_loc=$(command -v ccache)
            cache_file0="$HOME"/.bkcache0

            if [ -n "$CORES" ]; then
                cpu_avl_cores=${CORES}
            fi

            if [ -n "$BUILD_OUTPUT_DIR" ]; then
                kl_out_dir="$BUILD_OUTPUT_DIR"
            fi
        }

        build_kernel_work_cmds() {
            if [ ! -f "$kl_conf" ]; then
                if [ -f "$kl_vendor_conf" ]; then
                    kl_conf_make="$kl_vendor_conf_make"
                else
                    script_death "" "" "" "Cannot find ${KL_DCONF}" "" ""
                fi
            fi

            if [ -f "$cache_file0" ]; then
                grep -Fq "kl.dir=${KL_DIR}" "$cache_file0"
                grep_rc=$(printf "%d" "$?")

                if [ $grep_rc -ne 0 ]; then
                    rm -f "$cache_file0"
                fi
            fi

            if [ -n "$TC_DIR" ]; then
                cd "$TC_DIR"/lib/gcc
                cd_rc=$(printf "%d" "$?")

                if [ $cd_rc -ne 0 ]; then
                    script_death "cd" "${cd_rc}" "$LINENO" \
                                 "Cannot determine toolchain prefix" "" ""
                fi

                cd -- *
                cd_rc=$(printf "%d" "$?")

                if [ $cd_rc -ne 0 ]; then
                    script_death "cd" "${cd_rc}" "$LINENO" \
                                 "Cannot determine toolchain prefix" "" ""
                fi

                tc_prefix=$(basename "$PWD")-
            fi
        }

        build_kernel_work_env() {
            KBUILD_OUTPUT="$kl_out_dir"
            KBUILD_BUILD_USER=$(id -un)
            KBUILD_BUILD_HOST=$(uname -n)
            ARCH=$KL_ARCH
            SUBARCH=$KL_ARCH

            if [ -n "$BUILD_USER" ]; then
                KBUILD_BUILD_USER=$BUILD_USER
            fi

            if [ -n "$BUILD_HOST" ]; then
                KBUILD_BUILD_HOST=$BUILD_HOST
            fi

            if [ -n "$TC_DIR" ]; then
                CROSS_COMPILE="${TC_DIR}/bin/${tc_prefix}"

                if [ $CCACHE -eq 1 ]; then
                    CROSS_COMPILE="${ccache_loc} ${CROSS_COMPILE}"
                fi

                export CROSS_COMPILE
            fi

            if [ -n "$LOCALVERSION" ]; then
                export LOCALVERSION=$LOCALVERSION
            fi

            export KBUILD_OUTPUT
            export KBUILD_BUILD_USER
            export KBUILD_BUILD_HOST
            export ARCH
            export SUBARCH
        }

        build_kernel_work_vars;
        build_kernel_work_cmds;
        build_kernel_work_env;
    }

    build_kernel_exec() {
        build_kernel_exec_work() {
            cd "$KL_DIR"
            cd_rc=$(printf "%d" "$?")

            if [ $cd_rc -ne 0 ]; then
                script_death "cd" "${cd_rc}" "$LINENO" "" "" ""
            fi

            if [ $CLEAN_BUILD -eq 1 ]; then
                if [ -d "$kl_out_dir" ]; then
                    rm -rf "$kl_out_dir"
                fi

                if [ -f "$kl_conf_obj" ]; then
                    (unset KBUILD_OUTPUT; make clean && make mrproper)
                fi
            fi

            dsstart=$(date +%s)
        }

        build_kernel_exec_cc() {
            if [ $CLANG -eq 1 ]; then
                CC=$clang_loc
            else
                CC=$gcc_loc
            fi

            if [ $CCACHE -eq 1 ]; then
                CC="$ccache_loc $CC"
            fi

            if [ -n "$TC_DIR" ]; then
                make $kl_conf_make \
                     -j${cpu_avl_cores}
            else
                make CC="${CC}" \
                     $kl_conf_make \
                     -j${cpu_avl_cores}
            fi

            make_rc=$(printf "%d" "$?")

            if [ $make_rc -ne 0 ]; then
                script_death "make" "${make_rc}" "" "Cannot generate .config" \
                             "" ""
            fi

            if [ -n "$TC_DIR" ]; then
                make -j${cpu_avl_cores}
            else
                make CC="${CC}" \
                     -j${cpu_avl_cores}
            fi

            make_rc=$(printf "%d" "$?")

            if [ $make_rc -ne 0 ]; then
                script_death "make" "${make_rc}" "" "Compilation has errors" \
                             "" ""
            fi
        }

        build_kernel_exec_post() {
            dsend=$(date +%s)
            bfdate=$(date "+%b %-e, %T %:z")
        }

        build_kernel_exec_work;
        build_kernel_exec_cc;
        build_kernel_exec_post;
    }

    build_kernel_work;
    build_kernel_exec;
}

report() {
    report_work() {
        echo
    }

    report_success() {
        text_clr "green"
        echo "The kernel is compiled successfully!"
        text_clr "def"
    }

    report_work;
    report_success;
}

zipper() {
    zipper_work() {
        zipper_work_vars() {
            kl_img0="$kl_out_dir"/arch/$KL_ARCH/boot/bzImage
            kl_img1="$kl_out_dir"/arch/$KL_ARCH/boot/Image.gz
            kl_img_dtb0="$kl_out_dir"/arch/$KL_ARCH/boot/Image.gz-dtb
            ymd_date=$(date +%Y%m%d)
        }

        zipper_work_cmds() {
            if [ -f "$kl_img0" ]; then
                kl_img="$kl_img0"
            elif [ -f "$kl_img1" ]; then
                kl_img="$kl_img1"
            fi

            if [ -f "$kl_img_dtb0" ]; then
                kl_img_dtb="$kl_img_dtb0"
            fi

            cd "$ZP_DIR"
            cd_rc=$(printf "%d" "$?")

            if [ $cd_rc -ne 0 ]; then
                script_death "cd" "${cd_rc}" "$LINENO" "" "" ""
            fi

            echo

            git clean -fdx
        }

        zipper_work_filename() {
            zp_filename=$ZP_KL_NAME

            if [ -n "$ZP_KL_VERSION" ]; then
                zp_filename=${zp_filename}-$ZP_KL_VERSION
            fi

            if [ -n "$ZP_KL_DEVICE" ]; then
                zp_filename=${zp_filename}-$ZP_KL_DEVICE
            fi

            if [ $ZP_APPEND_DATE -eq 1 ]; then
                zp_filename=${zp_filename}-$ymd_date
            fi

            zp_filename=${zp_filename}.zip
        }

        zipper_work_vars;
        zipper_work_cmds;
        zipper_work_filename;
    }

    zipper_exec() {
        zipper_exec_copy() {
            if [ $ZP_COPY_DTB_IMG -eq 1 ]; then
                if [ -n "$kl_img_dtb" ]; then
                    cp "$kl_img_dtb" "$ZP_DIR"
                fi
            else
                if [ -n "$kl_img" ]; then
                    cp "$kl_img" "$ZP_DIR"
                fi
            fi
        }

        zipper_exec_zip() {
            zip -FSr9 $zp_filename ./* -x .git
        }

        zipper_exec_copy;
        zipper_exec_zip;
    }

    zipper_work;
    zipper_exec;
}

install() {
    install_work() {
        install_work_vars() {
            kl_mkfile="$KL_DIR"/Makefile
        }

        install_work_cmds() {
            kl_ver=$(grep -w "VERSION =" "$kl_mkfile" | cut -d " " -f3)
            kl_plvl=$(grep -w "PATCHLEVEL =" "$kl_mkfile" | cut -d " " -f3)

            cd "$kl_out_dir"
            cd_rc=$(printf "%d" "$?")

            if [ $cd_rc -ne 0 ]; then
                script_death "cd" "${cd_rc}" "$LINENO" "" "" ""
            fi

            echo
        }

        install_work_cp_args() {
            cp_args=arch/$KL_ARCH/boot/bzImage
            cp_args="${cp_args} /boot/vmlinuz-${kl_ver}${kl_plvl}"
        }

        install_work_vars;
        install_work_cmds;
        install_work_cp_args;
    }

    install_exec() {
        install_exec_img() {
            su -c "cp -v ${cp_args}"
        }

        install_exec_grub() {
            su -c "grub-mkconfig -o /boot/grub/grub.cfg"
        }

        install_exec_img;
        install_exec_grub;
    }

    install_work;
    install_exec;
}

stats() {
    stats_work() {
        echo
        text_clr "white"
    }

    stats_user() {
        printf "> User: %s" "${KBUILD_BUILD_USER}"
        echo
    }

    stats_host() {
        printf "> Host: %s" "${KBUILD_BUILD_HOST}"
        echo
    }

    stats_comp() {
        stats_comp_work() {
            comp_time=$((dsend - dsstart))
            comp_time_mins=$((comp_time / 60))
            comp_time_secs=$((comp_time % 60))
            comp_time_mins_noun=minutes
            comp_time_secs_noun=seconds

            if [ $comp_time_mins -eq 1 ]; then
                comp_time_mins_noun=minute
            fi

            if [ $comp_time_secs -eq 1 ]; then
                comp_time_secs_noun=second
            fi
        }

        stats_comp_exec() {
            printf "> Compilation took: %d %s and %d %s" \
                   "${comp_time_mins}" \
                   "${comp_time_mins_noun}" \
                   "${comp_time_secs}" \
                   "${comp_time_secs_noun}"
            echo

            printf "> Compilation finished at: %s" "${bfdate}"
            echo
        }

        stats_comp_work;
        stats_comp_exec;
    }

    stats_img() {
        stats_img_work() {
            stats_img_work_vars() {
                kl_img0="$kl_out_dir"/arch/$KL_ARCH/boot/bzImage
                kl_img1="$kl_out_dir"/arch/$KL_ARCH/boot/Image.gz
                kl_img_dtb0="$kl_out_dir"/arch/$KL_ARCH/boot/Image.gz-dtb
            }

            stats_img_work_cmds() {
                if [ -f "$kl_img0" ]; then
                    kl_img="$kl_img0"
                elif [ -f "$kl_img1" ]; then
                    kl_img="$kl_img1"
                fi

                if [ -f "$kl_img_dtb0" ]; then
                    kl_img_dtb="$kl_img_dtb0"
                fi

                if [ -n "$kl_img" ]; then
                    kl_img_bytes=$(ls -n "$kl_img" | awk '{print $5}')
                    kl_img_bsize=$(convert_binary_bytes "$kl_img_bytes")
                    kl_img_msize=$(convert_metric_bytes "$kl_img_bytes")

                    if cmd_available md5sum; then
                        kl_img_md5=$(md5sum "$kl_img" | cut -d ' ' -f 1)
                    fi

                    if cmd_available sha1sum; then
                        kl_img_sha1=$(sha1sum "$kl_img" | cut -d ' ' -f 1)
                    fi
                fi

                if [ -n "$kl_img_dtb" ]; then
                    kl_img_dtb_bytes=$(ls -n "$kl_img_dtb" | awk '{print $5}')
                    kl_img_dtb_bsize=$(convert_binary_bytes "$kl_img_dtb_bytes")
                    kl_img_dtb_msize=$(convert_metric_bytes "$kl_img_dtb_bytes")

                    if cmd_available md5sum; then
                        kl_img_dtb_md5=$(md5sum "$kl_img_dtb" | \
                                         cut -d ' ' -f 1)
                    fi

                    if cmd_available sha1sum; then
                        kl_img_dtb_sha1=$(sha1sum "$kl_img_dtb" | \
                                          cut -d ' ' -f 1)
                    fi
                fi

                if [ -f "$cache_file0" ]; then
                    if grep -Fq "img.bsize" "$cache_file0"; then
                        kl_img_bsize_old=$(grep img.bsize "$cache_file0" | \
                                           cut -d "=" -f2)
                    fi

                    if grep -Fq "img.msize" "$cache_file0"; then
                        kl_img_msize_old=$(grep img.msize "$cache_file0" | \
                                           cut -d "=" -f2)
                    fi

                    if grep -Fq "img.dtb.bsize" "$cache_file0"; then
                        kl_img_dtb_bsize_old=$(grep img.dtb.bsize \
                                               "$cache_file0" | cut -d "=" -f2)
                    fi

                    if grep -Fq "img.dtb.msize" "$cache_file0"; then
                        kl_img_dtb_msize_old=$(grep img.dtb.msize \
                                               "$cache_file0" | cut -d "=" -f2)
                    fi

                    if [ -n "$kl_img_bsize_old" ] && \
                       [ -n "$kl_img_msize_old" ]; then
                        kl_img_size_old=$(printf " (prev %s / %s)" \
                                          "${kl_img_bsize_old}" \
                                          "${kl_img_msize_old}")
                    fi

                    if [ -n "$kl_img_dtb_bsize_old" ] && \
                       [ -n "$kl_img_dtb_msize_old" ]; then
                        kl_img_dtb_size_old=$(printf " (prev %s / %s)" \
                                              "${kl_img_dtb_bsize_old}" \
                                              "${kl_img_dtb_msize_old}")
                    fi
                fi
            }

            stats_img_work_vars;
            stats_img_work_cmds;
        }

        stats_img_exec() {
            if [ -n "$kl_img" ]; then
                printf "> Image location: %s" "${kl_img}"
                echo

                printf "> Image size: %s / %s" "${kl_img_bsize}" \
                                               "${kl_img_msize}"
                if [ -n "$kl_img_size_old" ]; then
                    printf "%s" "${kl_img_size_old}"
                fi
                echo

                if [ -n "$kl_img_md5" ]; then
                    printf "> Image MD5: %s" "${kl_img_md5}"
                    echo
                fi

                if [ -n "$kl_img_sha1" ]; then
                    printf "> Image SHA-1: %s" "${kl_img_sha1}"
                    echo
                fi
            fi

            if [ -n "$kl_img_dtb" ]; then
                printf "> Image-dtb location: %s" "${kl_img_dtb}"
                echo

                printf "> Image-dtb size: %s / %s" "${kl_img_dtb_bsize}" \
                                                   "${kl_img_dtb_msize}"
                if [ -n "$kl_img_dtb_size_old" ]; then
                    printf "%s" "${kl_img_dtb_size_old}"
                fi
                echo

                if [ -n "$kl_img_dtb_md5" ]; then
                    printf "> Image-dtb MD5: %s" "${kl_img_dtb_md5}"
                    echo
                fi

                if [ -n "$kl_img_dtb_sha1" ]; then
                    printf "> Image-dtb SHA-1: %s" "${kl_img_dtb_sha1}"
                    echo
                fi
            fi
        }

        stats_img_work;
        stats_img_exec;
    }

    stats_zip() {
        stats_zip_work() {
            stats_zip_work_vars() {
                zp_file0="$ZP_DIR"/$zp_filename
            }

            stats_zip_work_cmds() {
                if [ -f "$zp_file0" ]; then
                    zp_file="$zp_file0"
                fi

                if [ -n "$zp_file" ]; then
                    zp_file_bytes=$(ls -n "$zp_file" | awk '{print $5}')
                    zp_file_bsize=$(convert_binary_bytes "$zp_file_bytes")
                    zp_file_msize=$(convert_metric_bytes "$zp_file_bytes")

                    if cmd_available md5sum; then
                        zp_file_md5=$(md5sum "$zp_file" | cut -d ' ' -f 1)
                    fi

                    if cmd_available sha1sum; then
                        zp_file_sha1=$(sha1sum "$zp_file" | cut -d ' ' -f 1)
                    fi
                fi

                if [ -f "$cache_file0" ]; then
                    if grep -Fq "zip.bsize" "$cache_file0"; then
                        zp_file_bsize_old=$(grep zip.bsize "$cache_file0" | \
                                            cut -d "=" -f2)
                    fi

                    if grep -Fq "zip.msize" "$cache_file0"; then
                        zp_file_msize_old=$(grep zip.msize "$cache_file0" | \
                                            cut -d "=" -f2)
                    fi

                    if [ -n "$zp_file_bsize_old" ] && \
                       [ -n "$zp_file_msize_old" ]; then
                        zp_file_size_old=$(printf " (prev %s / %s)" \
                                           "${zp_file_bsize_old}" \
                                           "${zp_file_msize_old}")
                    fi
                fi
            }

            stats_zip_work_vars;
            stats_zip_work_cmds;
        }

        stats_zip_exec() {
            if [ -n "$zp_file" ]; then
                printf "> Zip location: %s" "${zp_file}"
                echo

                printf "> Zip size: %s / %s" "${zp_file_bsize}" \
                                             "${zp_file_msize}"
                if [ -n "$zp_file_size_old" ]; then
                    printf "%s" "${zp_file_size_old}"
                fi
                echo

                if [ -n "$zp_file_md5" ]; then
                    printf "> Zip MD5: %s" "${zp_file_md5}"
                    echo
                fi

                if [ -n "$zp_file_sha1" ]; then
                    printf "> Zip SHA-1: %s" "${zp_file_sha1}"
                    echo
                fi
            fi
        }

        stats_zip_work;
        stats_zip_exec;
    }

    stats_post() {
        text_clr "def"
    }

    stats_work;
    stats_user;
    stats_host;
    stats_comp;
    stats_img;
    stats_zip;
    stats_post;
}

finish() {
    finish_work() {
        rm -f "$cache_file0"
        touch "$cache_file0"

        {
            printf "kl.dir=%s\n" "${KL_DIR}"
            printf "user=%s\n" "${KBUILD_BUILD_USER}"
            printf "host=%s\n" "${KBUILD_BUILD_HOST}"
            printf "comp.time=%dm %ds\n" "${comp_time_mins}" "${comp_time_secs}"
            printf "comp.finish=%s\n" "${bfdate}"

            if [ -n "$kl_img" ]; then
                printf "img.loc=%s\n" "${kl_img}"
                printf "img.bsize=%s\n" "${kl_img_bsize}"
                printf "img.msize=%s\n" "${kl_img_msize}"

                if [ -n "$kl_img_md5" ]; then
                    printf "img.md5=%s\n" "${kl_img_md5}"
                fi

                if [ -n "$kl_img_sha1" ]; then
                    printf "img.sha1=%s\n" "${kl_img_sha1}"
                fi
            fi

            if [ -n "$kl_img_dtb" ]; then
                printf "img.dtb.loc=%s\n" "${kl_img_dtb}"
                printf "img.dtb.bsize=%s\n" "${kl_img_dtb_bsize}"
                printf "img.dtb.msize=%s\n" "${kl_img_dtb_msize}"

                if [ -n "$kl_img_dtb_md5" ]; then
                    printf "img.dtb.md5=%s\n" "${kl_img_dtb_md5}"
                fi

                if [ -n "$kl_img_dtb_sha1" ]; then
                    printf "img.dtb.sha1=%s\n" "${kl_img_dtb_sha1}"
                fi
            fi

            if [ -n "$zp_file" ]; then
                printf "zip.loc=%s\n" "${zp_file}"
                printf "zip.bsize=%s\n" "${zp_file_bsize}"
                printf "zip.msize=%s\n" "${zp_file_msize}"

                if [ -n "$zp_file_md5" ]; then
                    printf "zip.md5=%s\n" "${zp_file_md5}"
                fi

                if [ -n "$zp_file_sha1" ]; then
                    printf "zip.sha1=%s\n" "${zp_file_sha1}"
                fi
            fi
        } >> "$cache_file0"
    }

    finish_exec() {
        echo
    }

    finish_work;
    finish_exec;
}

variables;
helpers;
probe_vars;
env_check;
pkg_check;
clone;
sync;
build_kernel;
report;

if [ -n "$ZP_DIR" ]; then
    zipper;
fi

if [ $INSTALL -eq 1 ]; then
    install;
fi

stats;
finish;
