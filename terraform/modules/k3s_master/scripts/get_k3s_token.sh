#!/bin/bash -e

eval "$(jq -r '@sh "hostname=\(.hostname) user=\(.user) private_key_file=\(.private_key_file)"')"

k3s_token=$(ssh -i "${private_key_file}" -o StrictHostKeyChecking=no "${user}@${hostname}" "cat /var/lib/rancher/k3s/server/token") 

jq -n --arg k3s_token "$k3s_token" '{k3s_token: $k3s_token}'