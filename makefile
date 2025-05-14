install:
	cd ansible; ansible-playbook -i inventory.yml playbook.yml --ask-become-pass

reinstall:
	cd ansible; ansible-playbook -i inventory.yml playbook.yml --ask-become-pass --extra-vars "reinstall=true"

inventory:
	cd ansible; ansible-inventory -i inventory.yml --graph

hide:
	git secret hide -m -P

reveal:
	git secret reveal -f -P

kube:
	cd kubernetes; kubectl kustomize . --enable-helm | kubectl apply -f -

CPU=$(shell dpkg --print-architecture)

install-sops:
	cd $(shell mktemp -d)
	curl -LO https://github.com/getsops/sops/releases/download/v3.10.2/sops-v3.10.2.linux.amd64
	sudo mv sops-v3.10.2.linux.amd64 /usr/local/bin/sops
	sudo chmod +x /usr/local/bin/sops

install-helm:
	curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
	sudo apt-get install apt-transport-https --yes
	echo "deb [arch=${CPU} signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
	sudo apt-get update
	sudo apt-get install helm

install-helmfile:
	cd $(shell mktemp -d)
	sudo wget https://github.com/helmfile/helmfile/releases/download/v0.159.0/helmfile_0.159.0_linux_amd64.tar.gz
	sudo tar -xxf helmfile_0.159.0_linux_amd64.tar.gz
	sudo rm helmfile_0.159.0_linux_amd64.tar.gz
	sudo mv helmfile /usr/local/bin/
	helmfile init

install-misc:
	sudo apt-get install age

install-deps: install-sops install-helm install-helmfile install-misc
	@echo "Done"
