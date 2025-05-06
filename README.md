# homelab 

## Taskfile

### Install

```shell
sh -c "$(curl --location https://taskfile.dev/install.sh)" -- -d -b ~/.local/bin
```

## Helm & Helmfile

### Install

```shell
# Helm
curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
sudo apt-get install apt-transport-https --yes
echo "deb [arch=${CPU} signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt-get update
sudo apt-get install helm

# Helmfile
cd $(shell mktemp -d)
sudo wget https://github.com/helmfile/helmfile/releases/download/v0.159.0/helmfile_0.159.0_linux_amd64.tar.gz
sudo tar -xxf helmfile_0.159.0_linux_amd64.tar.gz
sudo rm helmfile_0.159.0_linux_amd64.tar.gz
sudo mv helmfile /usr/local/bin/
helmfile init
```