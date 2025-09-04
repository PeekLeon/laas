#!/bin/bash

# Symbolic link
if [ "$APP_PATH" != "/" ]; then
    rm -f /workdir /data
    ln -fs "${APP_PATH%/}/workdir" /workdir
    ln -fs "${APP_PATH%/}/data" /data
else
    echo "Skipping symlink creation as APP_PATH is set to root (/)"
fi

# Default data directories
mkdir -p /data/scan-trivy && mkdir -p /data/gitlab-var && mkdir -p /data/kube/quota && chown -R root:sudo /data/kube/ && chmod -R 774 /data/kube/ && mkdir -p /data/scan-zap && chown 1000:1000 -R /data/scan-trivy

# Default workspace configuration
if [ -e "/root/.config/code-server/.code-workspace" ]; then
  echo "info Default workspace config file already exist"
else
  echo "info  Wrote default workspace config file to /root/.config/code-server/.code-workspace"
  mkdir -p /root/.config/code-server/
  cp /.laas-config/code-server/.code-workspace /root/.config/code-server/.code-workspace
fi

# Default starship configuration
if [ -e "/root/.config/starship.toml" ]; then
  echo "info Default starship config file already exist"
else
  echo "info  Wrote default starship config file to /root/.config/starship.toml"
  mkdir -p /root/.config/
  cp /.laas-config/starship.toml /root/.config/starship.toml
fi

# Default settings configuration
if [ -e "/root/.local/share/code-server/User/settings.json" ]; then
  echo "info Default settings config file already exist"
else
  echo "info  Wrote default settings config file to /root/.local/share/code-server/User/settings.json"
  mkdir -p /root/.local/share/code-server/User/
  cp /.laas-config/code-server/settings.json /root/.local/share/code-server/User/settings.json
fi

## User configuration
if [ ! -e "/root/.zshrc" ]; then
    echo "source /.laas-config/common.zshrc" > /root/.zshrc
fi

echo "info Kube users profiles initialisation"
if [ -z "$(find /kube-profiles -mindepth 1 -maxdepth 1 -type d)" ]; then
    echo "No user profile to initialize"
else
  for dir in /kube-profiles/*; do
      if [ -d "$dir" ]; then
          dir_name=$(basename "$dir")
          echo "- $dir_name"
          new-kube-profile $dir_name
      fi
  done
fi

# git hooks
git config --global core.hooksPath /usr/share/.git-hooks

# Configure Git
git config --global credential.helper store
CONFIG_FILE="/.laas-config/.git_users.conf"
mkdir -p "$(dirname "$CONFIG_FILE")"
> "$CONFIG_FILE"
PREFIX_LOGIN="GIT_LOGIN_"
PREFIX_PASS="GIT_PASSWORD_"
PREFIX_EMAIL="GIT_EMAIL_"
PREFIX_NAME="GIT_NAME_"

declare -A LOGIN
declare -A PASSWORDS
declare -A EMAIL
declare -A NAME

while IFS='=' read -r name value; do
    if [[ $name == ${PREFIX_LOGIN}* ]]; then
        suffix=${name#$PREFIX_LOGIN}
        LOGIN[$suffix]="$value"
    elif [[ $name == ${PREFIX_PASS}* ]]; then
        suffix=${name#$PREFIX_PASS}
        PASSWORDS[$suffix]="$value"
    elif [[ $name == ${PREFIX_EMAIL}* ]]; then
        suffix=${name#$PREFIX_EMAIL}
        EMAIL[$suffix]="$value"
    elif [[ $name == ${PREFIX_NAME}* ]]; then
        suffix=${name#$PREFIX_NAME}
        NAME[$suffix]="$value"
    fi
done < <(env)

suffix_to_url() {
  local s="$1"
  echo "${s,,}" | sed 's/_/./g'
}

for suffix in "${!LOGIN[@]}"; do
    login=${LOGIN[$suffix]}
    pass=${PASSWORDS[$suffix]}
    email=${EMAIL[$suffix]}
    name=${NAME[$suffix]}
    url=$(suffix_to_url "$suffix")
    echo "info URL: $url, Login: $login, email: $email, name: $name"
    echo -e "protocol=https\nhost=${url}\nusername=${login//@/%40}\npassword=${pass}" | git credential approve
    echo "$url|$name|$email" >> "$CONFIG_FILE"
    if [[ $? -eq 0 ]];then
      echo "info Git configuration OK"
    else
      echo "error: Git configuration"
    fi
done

# code-server extensiosn
# Install default extensions
VS_INSTALL_DEFAULT_EXTENSIONS_LOWER=$(echo "$VS_INSTALL_DEFAULT_EXTENSIONS" | tr '[:upper:]' '[:lower:]')

# Check if the environment variable is set to true (in any case) or 1
if [ "$VS_INSTALL_DEFAULT_EXTENSIONS_LOWER" = "true" ] || [ "$VS_INSTALL_DEFAULT_EXTENSIONS_LOWER" = "1" ]; then
    echo "info Default vs code extensions installation"
    while IFS= read -r extension || [ -n "$extension" ]; do
    # Install each extension
    code-server --install-extension "$extension"
    done < /.laas-config/code-server/default-extensions.txt
fi

# favicon
rm -f /usr/lib/code-server/src/browser/media/pwa*
cp /.laas-config/code-server/media/favicon.svg /usr/lib/code-server/src/browser/media/favicon.svg
cp /.laas-config/code-server/media/favicon.svg /usr/lib/code-server/src/browser/media/favicon-dark-support.svg
cp /.laas-config/code-server/media/favicon.ico /usr/lib/code-server/src/browser/media/favicon.ico


EXTRA_ENTRYPOINT="/.laas-config/entrypoint_extra.sh"
if [ -f "$EXTRA_ENTRYPOINT" ]; then
    echo "Sourcing $EXTRA_ENTRYPOINT..."
    # shellcheck source=/dev/null
    source "$EXTRA_ENTRYPOINT"
fi

# Clean gitlab password
while IFS='=' read -r name value; do
  if [[ $name == ${PREFIX_PASS}* ]]; then
    unset $name
  fi
done < <(env)

# Start code-server
/usr/lib/code-server/bin/code-server --bind-addr 0.0.0.0:8080