# 🧪 LaaS - Lab as a Service

## Installation

### Fonts

LAAS uses the **Fira Code Nerd font** with Starship, so you need to install it on your computer or in your web browser.

### Docker compose

```yaml
services:
  laas:
    image: peekleon/laas:latest
    hostname: laas
    ports:
      - 80:80
    volumes:
      # Workspace
      - "${APP_PATH}/workdir:${APP_PATH}/workdir"
      - "${APP_PATH}/data:${APP_PATH}/data/"
      # Users
      - "${APP_PATH}/kube-profiles:/kube-profiles"
      - "${APP_PATH}/root/:/root/"
      # Docker
      - "/var/run/docker.sock:/var/run/docker.sock:ro"
      - "/etc/localtime:/etc/localtime:ro"
    env_file:
      - .env
```
### .env

```sh
APP_PATH=/applications/laas/volumes
VS_INSTALL_DEFAULT_EXTENSIONS=true
GIT_LOGIN_GITLAB_COM=Dragomir
GIT_PASSWORD_GITLAB_COM=glpat-...
GIT_EMAIL_GITLAB_COM=ron.weasley@hogwarts.com
GIT_NAME_GITLAB_COM="Ron WEASLEY"
PASSWORD=🙈🙉🙊
PRE_COMMIT_HELM_LINT=true
PRE_COMMIT_GITLAB_LINT=true
PRE_COMMIT_GITLEAKS=true
```

| Variable | Description | Example / Default |
|----------|-------------|-----------------|
| `APP_PATH` | Path to your LaaS volumes | `/applications/laas/volumes` |
| `VS_INSTALL_DEFAULT_EXTENSIONS` | Install default extensions used in LaaS | `true` / `false` |
| `GIT_LOGIN_GITLAB_COM` | GitLab user| `Dragomir` |
| `GIT_PASSWORD_GITLAB_COM` | Your GitLab token | `glpat-...` |
| `GIT_EMAIL_GITLAB_COM` | Your email address | `ron.weasley@hogwarts.com` |
| `GIT_NAME_GITLAB_COM` | Your First Name LAST NAME | `Ron WEASLEY` |
| `PASSWORD` | Password to access VS Code | 🙈🙉🙊 |
| `PRE_COMMIT_HELM_LINT` | Check Helm charts on Git pre-commit | `true` / `false` |
| `PRE_COMMIT_GITLAB_LINT` | Check `.gitlab-ci.yml` files on Git pre-commit | `true` / `false` |
| `PRE_COMMIT_GITLEAKS` | Check for password leaks on Git pre-commit | `true` / `false` |

> You can have multiple account configurations for Git.  
> To do this, you can add GIT_ variables in the format `GIT_<SETTING>_<DOMAIN>` (for example, gitlab.com → GIT_LOGIN_GITLAB_COM).


## Settings

Settings are applied by default at startup from: `/.laas-config/code-server/settings.json` to :
`/root/.local/share/code-server/User/settings.json`
if the file does not already exist.

## Workspace

You can load the default workspace via:  
☰ -> File -> Open workspace from file... and select : 
`/root/.config/code-server/.code-workspace`

> You don't need to do this if you open the following URL :  
> `http://localhost/?workspace=/root/.config/code-server/.code-workspace`


## Commands / Tools

### klaas

- `klaas config new.userprofile <PROFILE NAME>`  
  Initialize a user account in `/kube-profiles/<profile-name>` to access a Kubernetes cluster.  
  > Example: `klaas config new.userprofile kube-staging`  
  > (We usually use the cluster name as the profile name.)  

  Then configure the kubeconfig with your token and copy it to: `/kube-profiles/<profile-name>/.kube/config`

- `klaas config set.namespace <NAMESPACE>`  
Select your namespace.  
> Example: `klaas config set.namespace my-namespace-ns`


- `klaas exec (bash/shell) <POD>`  
Enter a pod using bash or shell.  
> Example: `klaas exec bash my-pod-azerty`


- `klaas get namespace.quota <NAMESPACE(S)>`  
Get quotas for the specified namespaces or for all namespaces in the cluster (if no arg). The result will be saved in: `/data/kube/quota/<cluster-name>.csv`
> Example: `klaas get namespace.quota`  
> or `klaas get namespace.quota my-namespace my-namespace-2`

- `klaas get deployment.images`  
Get images used in a deployment (if specified) or all deployments in the current namespace. Useful to quickly check deployed versions.  
> Example: `klaas get deployment.images`


- `klaas get configmap <CONFIGMAP> (grep value)`  
Search for one or more values in a configmap (YAML format).  
> Example: `klaas get configmap back-configmap-env s3`

- `klaas logs (tmux.horizontal/tmux.vertical) <DEPLOYMENT(S)>`  
Display logs horizontally or vertically for all pods in the selected deployment(s) via tmux.

---

### trivy

- `trivy image <IMAGE>`  
Scan Docker images whith the latest trivy databases (use : `peekleon/trivy-updated-databases:latest` image). Results are saved in: `/data/scan-trivy`

> Example: `trivy image peekleon/laas:latest`

You can also set your own parameters using the env file:  `/.laas-config/trivy.env` 
> Example: `--debug` => `TRIVY_DEBUG`  
> Don’t forget to mount this file if you choose to use it.

## .zshrc

A default `.zshrc` is provided.  
You can also add your own custom configuration in: `/.laas-config/zsh_common_extra/yourzshrc.zsh`

## klaas extra

By default, some klaas commands are provided, but you can create your own custom commands.  
To do this, create a file in: `/.laas-config/klaas/extensions` named <action>_<fonction>.sh

example of klaas extension :

```bash
#!/bin/bash

get_configmap(){
  if [ -z "$2" ];then
    kubectl get configmaps -o yaml $1 
  else
    kubectl get configmaps -o yaml $1 |grep -i $2
  fi
}

get_configmap_completion() {
  klaas_get_configmap
}

register_klaas_extension "get" "configmap"
```

You can add completion functions using the pattern: <action>_<function>_completion.

some completion can be used :

- klaas_get_pods
- klaas_get_deployments
- klaas_get_serviceaccounts
- klaas_get_namespace
- klaas_get_configmap

register_klaas_extension `"<action>"` `"<fonction>"`