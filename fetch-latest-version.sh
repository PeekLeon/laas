#!/usr/bin/env bash
# set -euo pipefail

# Liste des repos à surveiller
# Format: "nom=repoGitHub"
declare -A repos=(
  [YQ]=mikefarah/yq
  [JQ]=jqlang/jq
  [KUBECONFORM]=yannh/kubeconform
  [MC]=minio/mc
  [STARSHIP]=starship/starship
  [HELM]=helm/helm
  [CODE_SERVER]=coder/code-server
)

# Fichier de sortie
OUTFILE="versions.env"
: > "$OUTFILE"

echo "# Versions générées automatiquement" >> "$OUTFILE"
echo "# $(date)" >> "$OUTFILE"

for name in "${!repos[@]}"; do
  repo="${repos[$name]}"
  version=$(curl -s https://api.github.com/repos/$repo/releases/latest \
            | grep tag_name | cut -d '"' -f4)
  echo "${name}_VERSION=$version" | tee -a "$OUTFILE"
done

version=$(curl -s https://api.github.com/repos/ohmyzsh/ohmyzsh/commits/master \
          | grep sha | head -n 1 | cut -d '"' -f4)
echo "OHMYZSH_VERSION=$version" | tee -a "$OUTFILE"

version=$(curl -L -s https://dl.k8s.io/release/stable.txt)
echo "KUBECTL_VERSION=$version" | tee -a "$OUTFILE"

version=$(apt-cache madison docker-ce | grep -v beta | head -n1 | awk '{print $3}')
echo "DOCKER_VERSION=$version" | tee -a "$OUTFILE"
