#!/bin/bash -e

eval "$(jq -r '@sh "hostname=\(.hostname) user=\(.user) private_key_file=\(.private_key_file) k3s_vip=\(.k3s_vip)"')"

kube_config=$(ssh -i "${private_key_file}" -o StrictHostKeyChecking=no "${user}@${hostname}" "cat /etc/rancher/k3s/k3s.yaml | sed 's|server: https://127.0.0.1:6443|server: https://${k3s_vip}:6443|'") 

jq -n --arg kube_config "${kube_config}" '{kube_config: $kube_config}'