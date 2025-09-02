
## check : gitlab lint
# Fichiers ciblés pour le lint GitLab
HOOK_CI_FILES="${HOOK_CI_FILES:-.gitlab-ci.yml,.gitlab-cd.yml}"
IFS="," read -r -a target_files <<< "$HOOK_CI_FILES"
for i in "${!target_files[@]}"; do
  target_files[$i]=$(echo "${target_files[$i]}" | xargs)
done

# target_files=(".gitlab-ci.yml" ".gitlab-cd.yml" ".gitlab-cd-dev.yml")

# Récupérer seulement les fichiers ajoutés (A) ou modifiés (M)
changed_files=$(git diff --cached --name-only --diff-filter=AM)

lint_files=()
for file in "${target_files[@]}"; do
  if echo "$changed_files" | grep -q "^$file$"; then
    lint_files+=("$file")
  fi
done

msg_output=""
if [ "${#lint_files[@]}" -ne 0 ]; then

  GITLAB_URL_ORIGIN=$(git remote get-url origin 2>/dev/null)
  GITLAB_CONDITIONS=1
  if [ -n "$GITLAB_URL_ORIGIN" ]; then
    msg_output+="🎯 L'URL du remote origin est : $GITLAB_URL_ORIGIN\n"
    GITLAB_DOM=$(echo "$GITLAB_URL_ORIGIN" | sed -E 's~^(https?://|git@)([^/:]+).*~\2~')
    GITLAB_PROJECT_PATH=$(echo "$GITLAB_URL_ORIGIN" | sed -E 's~https?://[^/]+/~~; s/\.git$//' | sed 's/\//%2F/g')
    ACCESS_TOKEN=$(grep -m 1 "$GITLAB_DOM" ~/.git-credentials | sed -n 's/https:\/\/[^:]*:\([^@]*\)@.*/\1/p')
    
    if [ -n "$ACCESS_TOKEN" ]; then
      msg_output+="🔑 Access token ok\n"
      GITLAB_PROJECT_ID=$(curl -s --header "PRIVATE-TOKEN: ${ACCESS_TOKEN}" \
      "https://${GITLAB_DOM}/api/v4/projects/${GITLAB_PROJECT_PATH}" \
      | jq '.id')

      
      if [[ "$GITLAB_PROJECT_ID" =~ ^-?[0-9]+$ ]]; then
        msg_output+="🏷️  Project id : ${GITLAB_PROJECT_ID}\n"
        for file in "${lint_files[@]}"; do
          msg_output+="🔍 Vérification de $file...\n"

          gitlab_lint=$(jq -s --null-input --arg yaml "$(<"$file")" '.content=$yaml' \
            | curl -s --url "https://${GITLAB_DOM}/api/v4/projects/${GITLAB_PROJECT_ID}/ci/lint?include_merged_yaml=true" \
            --header "Content-Type: application/json" --header "PRIVATE-TOKEN: ${ACCESS_TOKEN}" \
            --data @-)

          if [ "$(echo "$gitlab_lint" | jq -r '.valid')" = "true" ]; then
            msg_output+="✅ $file est valide\n"
          else
            msg_output+="❌ Erreurs dans $file\n"
            msg_output_vscode_git+=$(echo "$gitlab_lint" | jq -r '.errors[]')
            if [[ "$VSCODE_GIT_COMMAND" != "" ]]; then
              echo -e "${msg_output_vscode_git}"
              echo -e "${msg_output}"
            else
              echo -e "${msg_output}"
              echo -e "${msg_output_vscode_git}"
            fi
            exit 1
          fi
        done
      else
        msg_output+="🤷 Erreur dans le project id, gitlab lint ignoré\n"
      fi
    else
      msg_output+="🤷 Aucun ACCESS_TOKEN trouvé, gitlab lint ignoré\n"
    fi
  else
    msg_output+="🤷 Aucun remote 'origin' trouvé, gitlab lint ignoré\n"
  fi
fi
if [[ "$VSCODE_GIT_COMMAND" = "" ]]; then
  echo -e "${msg_output}"
fi