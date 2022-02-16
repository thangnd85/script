#!/bin/bash
#============================================================================================================================
# This file is licensed under the terms of the GNU General Public
# License version 2. This program is licensed "as is" without any
# warranty of any kind, whether express or implied.
#
# This file is a part of the script
# https://github.com/ophub/script
#
# Function: Armbian kernel update
# Copyright (C) 2021 https://github.com/unifreq
# Copyright (C) 2021 https://github.com/ophub/script
#
# Kernel download server: https://github.com/ophub/kernel/tree/main/pub
#
# Command: bash <(curl -fsSL git.io/armbian-kernel) <soc> <kernel_version> <version_branch> <mainline_uboot>
# Required command parameters: bash <(curl -fsSL git.io/armbian-kernel) <soc> <kernel_version>
# The kernel above version 5.10 needs to install mainline u-boot
# The mainline u-boot is installed by default: bash <(curl -fsSL git.io/armbian-kernel) s905x3 5.4.180 stable yes
# Don't write mainline u-boot command: bash <(curl -fsSL git.io/armbian-kernel) s905x3 5.4.180 stable no
#============================================================================================================================

echo -e "Ready to update, please wait..."

# Receive one-key command related parameters
INPUTS_SOC="${1}"
INPUTS_KERNEL="${2}"

# Specify version branch, such as: stable
ARR_BRANCH=("stable" "dev")
if [[ -n "${3}" && -n "$(echo "${ARR_BRANCH[@]}" | grep -w "${3}")" ]]; then
    version_branch="${3}"
else
    version_branch="stable"
fi

# Specify whether to brush into the mainline u-boot, such as: yes
if [[ "${4}" == "no" ]]; then
    AUTO_MAINLINE_UBOOT="no"
else
    AUTO_MAINLINE_UBOOT="yes"
fi

# The UBOOT_OVERLOAD and MAINLINE_UBOOT files download path
depends_repo="https://raw.githubusercontent.com/ophub/amlogic-s9xxx-armbian/main/build-armbian"

# Check the version on the server
SERVER_KERNEL_URL="https://api.github.com/repos/ophub/kernel/contents/pub/${version_branch}"

# Encountered a serious error, abort the script execution
error_msg() {
    echo -e "[Error] ${1}"
    exit 1
}

# Current device model
MYDEVICE_NAME=$(cat /proc/device-tree/model | tr -d '\000')
if [[ -z "${MYDEVICE_NAME}" ]]; then
    error_msg "The device name is empty and cannot be recognized."
elif [[ "$(echo ${MYDEVICE_NAME} | grep "Chainedbox L1 Pro")" != "" ]]; then
    MYDTB_FILE="rockchip"
    MYBOOT_VMLINUZ="Image"
elif [[ "$(echo ${MYDEVICE_NAME} | grep "BeikeYun")" != "" ]]; then
    MYDTB_FILE="rockchip"
    MYBOOT_VMLINUZ="Image"
elif [[ "$(echo ${MYDEVICE_NAME} | grep "V-Plus Cloud")" != "" ]]; then
    MYDTB_FILE="allwinner"
    MYBOOT_VMLINUZ="zImage"
else
    MYDTB_FILE="amlogic"
    MYBOOT_VMLINUZ="zImage"
fi
echo -e "Current device: ${MYDEVICE_NAME} [${MYDTB_FILE}]"
sleep 3

# Find the partition where root is located
ROOT_PTNAME=$(df / | tail -n1 | awk '{print $1}' | awk -F '/' '{print $3}')
if [ "${ROOT_PTNAME}" == "" ]; then
    error_msg "Cannot find the partition corresponding to the root file system!"
fi

# Find the disk where the partition is located, only supports mmcblk?p? sd?? hd?? vd?? and other formats
case ${ROOT_PTNAME} in
mmcblk?p[1-4])
    EMMC_NAME="$(echo ${ROOT_PTNAME} | awk '{print substr($1, 1, length($1)-2)}')"
    ;;
[hsv]d[a-z][1-4])
    EMMC_NAME="$(echo ${ROOT_PTNAME} | awk '{print substr($1, 1, length($1)-1)}')"
    ;;
*)
    error_msg "Unable to recognize the disk type of ${ROOT_PTNAME}!"
    ;;
esac
P4_PATH="${PWD}"

if [[ -z "${INPUTS_SOC}" ]]; then
    echo "The supported SOC types are: s905x3, s905x2, s905x, s905d, s912, s922x, l1pro, beikeyun, vplus"
    echo "Please enter the SOC type of your device, such as: s905x3"
    read AMLOGIC_SOC
    SOC="${AMLOGIC_SOC}"
else
    SOC="${INPUTS_SOC}"
fi
echo -e "SOC: ${SOC}"

# Download 4 kernel files
if [ $(ls ${P4_PATH}/*.tar.gz -l 2>/dev/null | grep "^-" | wc -l) -ne 3 ]; then

    if [[ -z "${INPUTS_KERNEL}" ]]; then
        LATEST_VERSION_K4_LATEST=$(curl -s "${SERVER_KERNEL_URL}" | grep "name" | grep -oE "5.4.[0-9]+" | sed -e "s/5.4.//g" | sort -n | sed -n '$p')
        LATEST_VERSION_K4="5.4.${LATEST_VERSION_K4_LATEST}"

        echo "Please enter the kernel version number, such as: ${LATEST_VERSION_K4}"
        read KERNEL_NUM
        if [ -n "${KERNEL_NUM}" ]; then
            INPUTS_KERNEL="${KERNEL_NUM}"
        else
            INPUTS_KERNEL="${LATEST_VERSION_K4}"
        fi
    fi

    echo -e "Kernel version: ${INPUTS_KERNEL}"
    echo -e "Start downloading the kernel from github.com ..."

    # Delete tmp files
    rm -f ${P4_PATH}/*${INPUTS_KERNEL}*.tar.gz 2>/dev/null
    sync

    # Download boot file
    SERVER_KERNEL_BOOT="$(curl -s "${SERVER_KERNEL_URL}/${INPUTS_KERNEL}" | grep "download_url" | grep -o "https.*/boot-.*.tar.gz" | head -n 1)"
    SERVER_KERNEL_BOOT_NAME="${SERVER_KERNEL_BOOT##*/}"
    SERVER_KERNEL_BOOT_NAME="${SERVER_KERNEL_BOOT_NAME//%2B/+}"
    wget -c "${SERVER_KERNEL_BOOT}" -O "${P4_PATH}/${SERVER_KERNEL_BOOT_NAME}" >/dev/null 2>&1 && sync
    if [[ "$?" -eq "0" && -s "${P4_PATH}/${SERVER_KERNEL_BOOT_NAME}" ]]; then
        echo -e "01.01 The boot file download complete."
    else
        error_msg "01.01 The boot file failed to download."
    fi

    # Download dtb file
    SERVER_KERNEL_DTB="$(curl -s "${SERVER_KERNEL_URL}/${INPUTS_KERNEL}" | grep "download_url" | grep -o "https.*/dtb-${MYDTB_FILE}-.*.tar.gz" | head -n 1)"
    SERVER_KERNEL_DTB_NAME="${SERVER_KERNEL_DTB##*/}"
    SERVER_KERNEL_DTB_NAME="${SERVER_KERNEL_DTB_NAME//%2B/+}"
    wget -c "${SERVER_KERNEL_DTB}" -O "${P4_PATH}/${SERVER_KERNEL_DTB_NAME}" >/dev/null 2>&1 && sync
    if [[ "$?" -eq "0" && -s "${P4_PATH}/${SERVER_KERNEL_DTB_NAME}" ]]; then
        echo -e "01.02 The dtb file download complete."
    else
        error_msg "01.02 The dtb file failed to download."
    fi

    # Download modules file
    SERVER_KERNEL_MODULES="$(curl -s "${SERVER_KERNEL_URL}/${INPUTS_KERNEL}" | grep "download_url" | grep -o "https.*/modules-.*.tar.gz" | head -n 1)"
    SERVER_KERNEL_MODULES_NAME="${SERVER_KERNEL_MODULES##*/}"
    SERVER_KERNEL_MODULES_NAME="${SERVER_KERNEL_MODULES_NAME//%2B/+}"
    wget -c "${SERVER_KERNEL_MODULES}" -O "${P4_PATH}/${SERVER_KERNEL_MODULES_NAME}" >/dev/null 2>&1 && sync
    if [[ "$?" -eq "0" && -s "${P4_PATH}/${SERVER_KERNEL_MODULES_NAME}" ]]; then
        echo -e "01.03 The modules file download complete."
    else
        error_msg "01.03 The modules file failed to download."
    fi

    # Download header file
    SERVER_KERNEL_HEADER="$(curl -s "${SERVER_KERNEL_URL}/${INPUTS_KERNEL}" | grep "download_url" | grep -o "https.*/header-.*.tar.gz" | head -n 1)"
    if [ -n "${SERVER_KERNEL_HEADER}" ]; then
        SERVER_KERNEL_HEADER_NAME="${SERVER_KERNEL_HEADER##*/}"
        SERVER_KERNEL_HEADER_NAME="${SERVER_KERNEL_HEADER_NAME//%2B/+}"
        wget -c "${SERVER_KERNEL_HEADER}" -O "${P4_PATH}/${SERVER_KERNEL_HEADER_NAME}" >/dev/null 2>&1 && sync
        if [[ "$?" -eq "0" && -s "${P4_PATH}/${SERVER_KERNEL_HEADER_NAME}" ]]; then
            echo -e "01.04 The header file download complete."
        else
            error_msg "01.04 The header file failed to download."
        fi
    fi

    sync
fi

if [ $(ls ${P4_PATH}/*${INPUTS_KERNEL}*.tar.gz -l 2>/dev/null | grep "^-" | wc -l) -ge 3 ]; then
    if [ $(ls ${P4_PATH}/boot-${INPUTS_KERNEL}-*.tar.gz -l 2>/dev/null | grep "^-" | wc -l) -ge 1 ]; then
        build_boot=$(ls ${P4_PATH}/boot-${INPUTS_KERNEL}-*.tar.gz | head -n 1) && build_boot=${build_boot##*/}
        flippy_version=${build_boot/boot-/} && flippy_version=${flippy_version/.tar.gz/}
        echo -e "flippy_version: ${flippy_version} "

        kernel_version=$(echo ${flippy_version} | grep -oE '^[1-9].[0-9]{1,2}.[0-9]+')
        kernel_vermaj=$(echo ${kernel_version} | grep -oE '^[1-9].[0-9]{1,2}')
        k510_ver=${kernel_vermaj%%.*}
        k510_maj=${kernel_vermaj##*.}
        if [ ${k510_ver} -eq "5" ]; then
            if [ "${k510_maj}" -ge "10" ]; then
                K510=1
            else
                K510=0
            fi
        elif [ ${k510_ver} -gt "5" ]; then
            K510=1
        else
            K510=0
        fi
    else
        error_msg "Have no boot-*.tar.gz file found in the ${P4_PATH} directory."
    fi

    if [ -f ${P4_PATH}/dtb-${MYDTB_FILE}-${flippy_version}.tar.gz ]; then
        build_dtb="dtb-${MYDTB_FILE}-${flippy_version}.tar.gz"
    else
        error_msg "Have no dtb-${MYDTB_FILE}-*.tar.gz file found in the ${P4_PATH} directory."
    fi

    if [ -f ${P4_PATH}/modules-${flippy_version}.tar.gz ]; then
        build_modules="modules-${flippy_version}.tar.gz"
    else
        error_msg "Have no modules-*.tar.gz file found in the ${P4_PATH} directory."
    fi

    if [ -f ${P4_PATH}/header-${flippy_version}.tar.gz ]; then
        build_header="header-${flippy_version}.tar.gz"
    else
        build_header=""
    fi
else
    error_msg "Please upload the kernel files to [ ${P4_PATH} ], then run [ $0 ] again."
fi

MODULES_OLD=$(ls /lib/modules/ 2>/dev/null)
VERSION_OLD=$(echo ${MODULES_OLD} | grep -oE '^[1-9].[0-9]{1,2}' 2>/dev/null)
VERSION_ver=${VERSION_OLD%%.*}
VERSION_maj=${VERSION_OLD##*.}
if [ ${VERSION_ver} -eq "5" ]; then
    if [ "${VERSION_maj}" -ge "10" ]; then
        V510=1
    else
        V510=0
    fi
elif [ ${VERSION_ver} -gt "5" ]; then
    V510=1
else
    V510=0
fi

# Check version consistency
if [[ "${V510}" -lt "${K510}" && "${MYDTB_FILE}" == "amlogic" ]]; then
    echo -e "Update to kernel 5.10 or higher and install U-BOOT."
    if [ -n "${SOC}" ]; then
        case ${SOC} in
        s905x3)
            UBOOT_OVERLOAD="u-boot-x96maxplus.bin"
            MAINLINE_UBOOT="x96maxplus-u-boot.bin.sd.bin"
            ;;
        s905x2)
            UBOOT_OVERLOAD="u-boot-x96max.bin"
            MAINLINE_UBOOT="x96max-u-boot.bin.sd.bin"
            ;;
        s905x)
            UBOOT_OVERLOAD="u-boot-p212.bin"
            MAINLINE_UBOOT=""
            ;;
        s905w)
            UBOOT_OVERLOAD="u-boot-s905x-s912.bin"
            MAINLINE_UBOOT=""
            ;;
        s905d)
            UBOOT_OVERLOAD="u-boot-n1.bin"
            MAINLINE_UBOOT=""
            ;;
        s912)
            UBOOT_OVERLOAD="u-boot-zyxq.bin"
            MAINLINE_UBOOT=""
            ;;
        s922x)
            UBOOT_OVERLOAD="u-boot-gtkingpro.bin"
            MAINLINE_UBOOT="gtkingpro-u-boot.bin.sd.bin"
            ;;
        *) error_msg "Unknown SOC, unable to update to kernel 5.10 and above." ;;
        esac

        # Check ${UBOOT_OVERLOAD}
        if [[ -n "${UBOOT_OVERLOAD}" ]]; then
            if [[ ! -s "/boot/${UBOOT_OVERLOAD}" ]]; then
                echo -e "Try to download the ${UBOOT_OVERLOAD} file from the server."
                GITHUB_UBOOT_OVERLOAD="${depends_repo}/amlogic-u-boot/${UBOOT_OVERLOAD}"
                #echo -e "UBOOT_OVERLOAD: ${GITHUB_UBOOT_OVERLOAD}"
                wget -c "${GITHUB_UBOOT_OVERLOAD}" -O "/boot/${UBOOT_OVERLOAD}" >/dev/null 2>&1 && sync
                if [[ "$?" -eq "0" && -s "/boot/${UBOOT_OVERLOAD}" ]]; then
                    echo -e "The ${UBOOT_OVERLOAD} file download is complete."
                else
                    error_msg "The ${UBOOT_OVERLOAD} file download failed. please try again."
                fi
            else
                echo -e "The ${UBOOT_OVERLOAD} file has been found."
            fi
        else
            error_msg "The 5.10 kernel cannot be used without UBOOT_OVERLOAD."
        fi

        # Check ${MAINLINE_UBOOT}
        if [[ -n "${MAINLINE_UBOOT}" && "${AUTO_MAINLINE_UBOOT}" == "yes" ]]; then
            if [[ ! -s "${MAINLINE_UBOOT}" ]]; then
                echo -e "Try to download the MAINLINE_UBOOT file from the server."
                GITHUB_MAINLINE_UBOOT="${depends_repo}/common-files/files/usr/lib/u-boot/${MAINLINE_UBOOT}"
                #echo -e "MAINLINE_UBOOT: ${GITHUB_MAINLINE_UBOOT}"
                [ -d "/lib/u-boot" ] || mkdir -p /lib/u-boot
                wget -c "${GITHUB_MAINLINE_UBOOT}" -O "/lib/u-boot/${MAINLINE_UBOOT}" >/dev/null 2>&1 && sync
                if [[ "$?" -eq "0" && -s "/lib/u-boot/${MAINLINE_UBOOT}" ]]; then
                    echo -e "The MAINLINE_UBOOT file download is complete."
                else
                    error_msg "The MAINLINE_UBOOT file download failed. please try again."
                fi
            fi
        fi
    else
        error_msg "Unknown SOC, unable to update."
    fi

    # Copy u-boot.ext and u-boot.emmc
    if [ -f "/boot/${UBOOT_OVERLOAD}" ]; then
        cp -f "/boot/${UBOOT_OVERLOAD}" /boot/u-boot.ext && sync && chmod +x /boot/u-boot.ext
        cp -f "/boot/${UBOOT_OVERLOAD}" /boot/u-boot.emmc && sync && chmod +x /boot/u-boot.emmc
        echo -e "The ${UBOOT_OVERLOAD} file copy is complete."
    else
        error_msg "The UBOOT_OVERLOAD file is missing and cannot be update."
    fi

    # Write Mainline bootloader
    if [[ -f "/lib/u-boot/${MAINLINE_UBOOT}" && "${AUTO_MAINLINE_UBOOT}" == "yes" ]]; then
        echo -e "Write Mainline bootloader: [ ${MAINLINE_UBOOT} ] to [ /dev/${EMMC_NAME} ]"
        dd if=/lib/u-boot/${MAINLINE_UBOOT} of=/dev/${EMMC_NAME} bs=1 count=442 conv=fsync
        dd if=/lib/u-boot/${MAINLINE_UBOOT} of=/dev/${EMMC_NAME} bs=512 skip=1 seek=1 conv=fsync
        echo -e "The MAINLINE_UBOOT file write is complete."
    fi
fi

echo -e "Unpack [ ${flippy_version} ] related files ..."

# 01. for /boot five files
rm -f /boot/config-* /boot/initrd.img-* /boot/System.map-* /boot/uInitrd-* /boot/vmlinuz-* 2>/dev/null && sync
rm -f /boot/uInitrd /boot/zImage /boot/Image 2>/dev/null && sync
tar -xzf ${P4_PATH}/${build_boot} -C /boot && sync

if [[ -f "/boot/uInitrd-${flippy_version}" ]]; then
    i=1
    max_try=10
    while [ "${i}" -le "${max_try}" ]; do
        cp -f /boot/uInitrd-${flippy_version} /boot/uInitrd 2>/dev/null && sync
        uInitrd_original=$(md5sum /boot/uInitrd-${flippy_version} | awk '{print $1}')
        uInitrd_new=$(md5sum /boot/uInitrd | awk '{print $1}')
        if [[ "${uInitrd_original}" == "${uInitrd_new}" ]]; then
            break
        else
            rm -f /boot/uInitrd && sync
            let i++
            continue
        fi
    done
    [ "${i}" -eq "10" ] && error_msg "/boot/uInitrd-${flippy_version} file copy failed."
else
    error_msg "/boot/uInitrd-${flippy_version} file is missing."
fi

if [[ -f "/boot/vmlinuz-${flippy_version}" ]]; then
    i=1
    max_try=10
    while [ "${i}" -le "${max_try}" ]; do
        cp -f /boot/vmlinuz-${flippy_version} /boot/${MYBOOT_VMLINUZ} 2>/dev/null && sync
        vmlinuz_original=$(md5sum /boot/vmlinuz-${flippy_version} | awk '{print $1}')
        vmlinuz_new=$(md5sum /boot/${MYBOOT_VMLINUZ} | awk '{print $1}')
        if [[ "${vmlinuz_original}" == "${vmlinuz_new}" ]]; then
            break
        else
            rm -f /boot/${MYBOOT_VMLINUZ} && sync
            let i++
            continue
        fi
    done
    [ "${i}" -eq "10" ] && error_msg "/boot/vmlinuz-${flippy_version} file copy failed."
else
    error_msg "/boot/vmlinuz-${flippy_version} file is missing."
fi

[ -f "/boot/config-${flippy_version}" ] || error_msg "/boot/config-${flippy_version} file is missing."
[ -f "/boot/System.map-${flippy_version}" ] || error_msg "/boot/System.map-${flippy_version} file is missing."

echo -e "02.01 Unpack [ ${build_boot} ] complete."
sleep 3

# 02 for /boot/dtb/${MYDTB_FILE}/*
[ -d /boot/dtb/${MYDTB_FILE} ] || mkdir -p /boot/dtb/${MYDTB_FILE}
if [[ "${MYDTB_FILE}" == "rockchip" ]]; then
    mkdir -p /boot/dtb-${flippy_version}/${MYDTB_FILE}
    ln -sf /boot/dtb-${flippy_version} /boot/dtb
fi
tar -xzf ${P4_PATH}/${build_dtb} -C /boot/dtb/${MYDTB_FILE} && sync
[ "$(ls /boot/dtb/${MYDTB_FILE} -l 2>/dev/null | grep "^-" | wc -l)" -ge "1" ] || error_msg "/boot/dtb/${MYDTB_FILE} file is missing."
echo -e "02.02 Unpack [ ${build_dtb} ] complete."
sleep 3

# 03 for /lib/modules/*
rm -rf /lib/modules/* 2>/dev/null && sync
tar -xzf ${P4_PATH}/${build_modules} -C /lib/modules && sync
(cd /lib/modules/${flippy_version} && echo "build source" | xargs rm -f)
[[ -d "/lib/modules/${flippy_version}" ]] || error_msg "/lib/modules/${flippy_version} kernel folder is missing."
echo -e "02.03 Unpack [ ${build_modules} ] complete."
sleep 3

# 04 for /usr/local/include/*
if [[ -n "${build_header}" && -f "${P4_PATH}/${build_header}" ]]; then
    rm -rf /use/local/include/* 2>/dev/null && sync
    tar -xzf ${P4_PATH}/${build_header} -C /usr/local && sync
    echo -e "02.04 Unpack [ ${build_header} ] complete."
    sleep 3
fi

rm -f ${P4_PATH}/*${flippy_version}*.tar.gz 2>/dev/null
sync
wait

echo "Successfully updated, automatic restarting..."
sleep 3
reboot
exit 0
