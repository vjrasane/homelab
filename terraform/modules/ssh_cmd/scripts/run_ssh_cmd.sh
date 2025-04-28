#!/bin/bash -e

eval "$(jq -r '@sh "hostname=\(.hostname) user=\(.user) private_key_file=\(.private_key_file) command=\(.command)"')"

result=$(ssh -i "${private_key_file}" -o StrictHostKeyChecking=no "${user}@${hostname}" "${command}") 

if [[ -z "${result}" ]] ; then 
  echo "Error: Command execution returned empty result."
  exit 1
fi

jq -n --arg result "${result}" '{result: $result}'