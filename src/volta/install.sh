#!/usr/bin/env bash
#-------------------------------------------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See https://go.microsoft.com/fwlink/?linkid=2090316 for license information.
#-------------------------------------------------------------------------------------------------------------

USERNAME=${USERNAME:-"automatic"}
VOLTA_VERSION=${VERSION:-'latest'}

set -eu

source /etc/os-release
source utils.sh

cleanup

if [ "$(id -u)" -ne 0 ]; then
    echo -e 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
    exit 1
fi

# Ensure that login shells get the correct path if the user updated the PATH using ENV.
rm -f /etc/profile.d/00-restore-env.sh
echo "export PATH=${PATH//$(sh -lc 'echo $PATH')/\$PATH}" > /etc/profile.d/00-restore-env.sh
chmod +x /etc/profile.d/00-restore-env.sh

# Determine the appropriate non-root user
if [ "${USERNAME}" = "auto" ] || [ "${USERNAME}" = "automatic" ]; then
    USERNAME=""
    POSSIBLE_USERS=("vscode" "node" "codespace" "$(awk -v val=1000 -F ":" '$3==val{print $1}' /etc/passwd)")
    for CURRENT_USER in "${POSSIBLE_USERS[@]}"; do
        if id -u ${CURRENT_USER} > /dev/null 2>&1; then
            USERNAME=${CURRENT_USER}
            break
        fi
    done
    if [ "${USERNAME}" = "" ]; then
        USERNAME=root
    fi
elif [ "${USERNAME}" = "none" ] || ! id -u ${USERNAME} > /dev/null 2>&1; then
    USERNAME=root
fi

check_packages curl ca-certificates

if [ "${VOLTA_VERSION}" = "latest" ] || version_greater_equal "${VOLTA_VERSION}" 1.1.0; then
    curl https://get.volta.sh | bash -s -- --version "${VOLTA_VERSION}"
 else
    curl https://raw.githubusercontent.com/volta-cli/volta/8f2074f423c65405dfba9858d9bcf393c38ffb45/dev/unix/volta-install.sh | bash -s -- --version "${VOLTA_VERSION}"
fi

export VOLTA_HOME="/${USERNAME}/.volta"
export PATH=$VOLTA_HOME/bin:$PATH