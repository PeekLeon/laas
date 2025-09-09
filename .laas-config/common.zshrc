export ZSH="/opt/oh-my-zsh"
eval "$(starship init zsh)"

plugins=(
  docker
  docker-compose
  git
  kubectl
  helm
)

source $ZSH/oh-my-zsh.sh

## Strarship
export STARSHIP_CONFIG=/.laas-config/starship.toml
precmd() { precmd() { echo } }
export LANG=C.UTF-8

# Wraps 'git clone' to automatically set user.name and user.email from a config file based on the repo URL.
git() {
  if [[ "$1" == "clone" ]]; then
    repo_url=$2
    target_dir=$3

    if [[ -z "$target_dir" ]]; then
      target_dir=$(basename "$repo_url" .git)
    fi

    command git clone "$repo_url" "$target_dir"

    cd "$target_dir" || return
    CONFIG_FILE="/.laas-config/.git_users.conf"

    while IFS='|' read -r domain name email; do
      if [[ "$repo_url" == *"$domain"* ]]; then
        command git config user.name "${name}"
        command git config user.email "$email"
        echo "Git configuration applied for ${target_dir} ($domain)"
        break
      fi
    done < "$CONFIG_FILE"

  else
    command git "$@"
  fi
}

## Scan trivy
trivy() {
  docker pull docker.io/peekleon/trivy-updated-databases:latest
  echo "---"
  if [[ "$1" == "image" ]]; then
    shift
    date_scan=$(date +%Y.%m.%d)
    image=$(echo ${1//\//_})
    scan_path=/data/scan-trivy
    scan_path_host=${APP_PATH}${scan_path}
    
    split_name_version=("${(@s[:])image}")
    if [ -z "$split_name_version[2]" ]; then
      split_name_version[2]=latest
    fi
    if [ ! -d "${scan_path}/${split_name_version[1]}" ]; then
      mkdir ${scan_path}/${split_name_version[1]}
    fi
    output=${split_name_version[1]}/$split_name_version[2]_${date_scan}
    docker run -e http_proxy=${http_proxy} -e https_proxy=${https_proxy} --rm -v /var/run/docker.sock:/var/run/docker.sock -v ${scan_path_host}:${scan_path} docker.io/peekleon/trivy-updated-databases:latest image --skip-db-update --skip-java-db-update -f json -o ${scan_path}/${output}.json ${@}
    docker run -e http_proxy=${http_proxy} -e https_proxy=${https_proxy} --rm -v /var/run/docker.sock:/var/run/docker.sock -v ${scan_path_host}:${scan_path} docker.io/peekleon/trivy-updated-databases:latest image --skip-db-update --skip-java-db-update -q -f table -o ${scan_path}/${output}.txt ${@}
    jq ' .Results[]| try .Vulnerabilities[] | {VulnerabilityID: .VulnerabilityID, Severity: .Severity, PkgName: .PkgName, PkgPath: .PkgPath, InstalledVersion: .InstalledVersion, FixedVersion: .FixedVersion, Status: .Status }' ${scan_path}/${output}.json > ${scan_path}/${output}_parsed.json && jq -s '.' ${scan_path}/${output}_parsed.json > ${scan_path}/${output}_formatted.json && mv ${scan_path}/${output}_formatted.json ${scan_path}/${output}_parsed.json > /dev/null 2>&1
  elif [[ "$1" == "version" ]]; then
    docker run --rm docker.io/peekleon/trivy-updated-databases:latest version
  fi
}

# klaas
# autoload -U +X bashcompinit && bashcompinit
autoload -U compinit; compinit

_klaas() {
  local extdir="/.laas-config/klaas/extensions"
  local state
  local -a commands types exts

  commands=(
    'get:Retrieve resources'
    'create:Create resources'
    'config:Manage configuration'
    'exec:Execute commands'
    'debug:Debug tools'
    'logs:Show logs'
  )

  exts=("${(@f)$(klaas list-extensions 2>/dev/null)}")

  _arguments -C \
    '1:command:->cmds' \
    '2:type:->types' \
    '*::arg:->args'

  case $state in
    cmds)
      _describe 'command' commands
      ;;
    types)
      local -a filtered
      local cmd=$words[2]
      for e in $exts; do
        if [[ $e == $cmd.* ]]; then
          filtered+="${e#${cmd}.}"
        fi
      done
      if (( ${#filtered} )); then
        _describe "${cmd} types" filtered
      fi
      ;;
    args)
      local cmd=$words[1]
      local typ=$words[2]

      local -a opts
      opts=("${(@f)$(klaas complete $cmd $typ "${words[@]:2}" 2>/dev/null)}")
      (( ${#opts} )) && _describe "${cmd} ${typ} options" opts
    ;;
  esac
}
compdef _klaas klaas

# Alias Kube
alias kcnup="klaas config new.userprofile"
alias kcsn="klaas config set.namespace"
alias ketib="klaas exec bash"
alias ketis="klaas exec shell"
alias kgcmv="klaas get configmap"
alias kgdi="klaas get deployment.images"
alias kltv="klaas logs tmux.vertical"
alias klth="klaas logs tmux.horizontal"

# Common extra
: ${COMMON_EXTRA_DIR:="/.laas-config/zsh_common_extra"}

if [ -d "$COMMON_EXTRA_DIR" ]; then
  setopt localoptions extendedglob nullglob
  files=("$COMMON_EXTRA_DIR"/*.zsh)
  files=("${(@on)files}")

  for f in "${files[@]}"; do
    [ -f "$f" ] && source "$f"
  done
fi