#!/bin/bash -e

eval "$(jq -r '@sh "hostname=\(.hostname) user=\(.user) private_key_file=\(.private_key_file) command=\(.command)"')"

result=$(ssh -o StrictHostKeyChecking=no -i "${private_key_file}" "${user}@${hostname}" "${command}") 

if [[ -z "${result}" ]] ; then 
  echo "Error: Command execution returned empty result."
  exit 1
fi

jq -n --arg result "${result}" '{result: $result}'