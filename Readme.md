# PKL-K8S

An experimental project that uses the **Apple PKL language** to maintain a **Kubernetes** cluster under **Proxmox**.  

This project features:
- A ModSecurity WAF ingress code example  
- A CertManager & Let's Encrypt code example  
- A basic Proxmox firewall deployment script  
- A basic script to fetch and deploy GitHub releases  
- A simple way to test locally using **k3d** and deploy to a remote cluster  

## License

This project is licensed under the [Educational Community License version 2.0 (ECL-2.0)](https://opensource.org/license/ecl-2-0).

## Requirements

Debian/Ubuntu 64 bits

## Usage 

- create a Settings.pkl at root using templates/Settings.demo.pkl 
- same for storage/backend/config.yaml using storage/backend/config.demo.yaml 
- create network/cluster.fw and network/nodes.sh
- update Settings.pkl according your github releases project

### local


First, install deps (see bellow sections).
Then use:
```bash on ubuntu server VM
sudo make # or just `make` on wsl
``` 

### deployement

Create proxmox instances, then create some VM with ubuntu server.
Then, install deps (see bellow sections) on all nodes.
Then checkup localnetworks and fill `network/cluster.fw`, `network/nodes.sh`.
Run `network/deploy.sh` to create correct firewall rules.
Run `scripts/deploy.sh` to create/update kubernetes cluster.


## TODO

- [ ] add a switch between k3d and k3s
- [ ] makefile should be easier to use/understand
- [ ] demo-pro-backend => change in the docker image. the app root to demo-pro-backend 
- [ ] maybe rename all demo-pro occurences to pro 
- [ ] pro/backend/.env => maybe we should add a PRO_ as prefix to avoid key colision or do differently like secretRef
- [ ] delete main-pv and do a main-demo instead (like main-pro) for storage with demo as a prefix instead of root, updating paths in demo deployements

## Dev machine

setup java if not done yet https://www.oracle.com/fr/java/technologies/downloads/
setup apple pkl vs code ext download and drag and drop to vscode https://github.com/apple/pkl-vscode/releases/latest

### Deps

*Basic apt deps:*

```bash
apt install jq make
```


*Kubectl:*

```bash
sudo snap install kubectl --classic

```

*setup helm*
```bash
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```


*k9s (to easily monitor the cluster):*
```bash
curl -sS https://webinstall.dev/k9s | bash
```


*Gh (to fetch github releases):*

```bash
sudo apt update
sudo apt install -y curl
type -p curl >/dev/null || sudo apt install curl -y
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | \
  sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) \
  signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] \
  https://cli.github.com/packages stable main" | \
  sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
sudo apt update
sudo apt install gh -y
```


*k3d (FOR DEV / PIPELINES):*

```bash
curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
```


*k3s for production (use nfs in settings.pkl with that!):*

```bash
curl -sfL https://get.k3s.io | sh -
```
