#!/bin/bash

script_dir=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
parent_dir="${script_dir}/.."
shared_dir="${HOME}/shared"
gnupg_dir="${HOME}/.gnupg"

source "${parent_dir}/restic.env" 

function backup {
    local path="$1"; shift;
    restic backup -H "${RESTIC_HOST}" "${path}"
}

crontab -l > "${parent_dir}/crontab.backup"
backup "${parent_dir}"
backup "${shared_dir}"
backup "${gnupg_dir}"
