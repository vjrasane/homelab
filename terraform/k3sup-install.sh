#!/bin/bash

k3sup install --ip 192.168.1.110 --ssh-key ./terraform/lxc_ssh_key.pem --tls-san 192.168.1.102 --cluster --user root --local-path ~/.kube/config --context k3s-ha --k3s-extra-args "disable servicelb --nodeip 192.168.1.110"