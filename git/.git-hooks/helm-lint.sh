#!/bin/bash

## check : helm lint
msg_output=""
HOOK_HELM_DIRS="${HOOK_HELM_DIRS:-helm-chart,helm-charts,bsl-chart}"
IFS="," read -r -a HELM_DIRS <<< "$HOOK_HELM_DIRS"
for i in "${!HELM_DIRS[@]}"; do
  HELM_DIRS[$i]=$(echo "${HELM_DIRS[$i]}" | xargs)
done

# HELM_DIRS=("helm-chart" "helm-charts" "bsl-chart")
for dir in "${HELM_DIRS[@]}"; do
  if [ -d "$dir" ]; then
    if git diff --cached --name-only --diff-filter=AM  | grep -q "^$dir/"; then
      msg_output+="🔍 Lint Helm charts ${dir} ..."

      rendered=$(helm template my-release "$dir" 2>&1)
      HELM_STATUS=$?

      if [ $HELM_STATUS -ne 0 ]; then
        msg_output_vscode_git+="❌ Le helm template à échoué"
        if [[ "$VSCODE_GIT_COMMAND" != "" ]]; then
          echo -e "${msg_output_vscode_git}"
          echo -e "${rendered}"
        else
          echo -e "${msg_output}"
          echo -e "${rendered}"
        fi
        exit 1
      fi

      msg_output+=$(echo "$rendered" | kubeconform -strict -output pretty 2>&1)
      LINT_STATUS=$?

      if [ $LINT_STATUS -ne 0 ]; then
        msg_output_vscode_git+="❌ Erreurs dans les charts Helm. Commit annulé."
        if [[ "$VSCODE_GIT_COMMAND" != "" ]]; then
          echo -e "${msg_output_vscode_git}"
          echo -e "${msg_output}"
        else
          echo -e "${msg_output}"
          echo -e "${msg_output_vscode_git}"
        fi
        exit 1
      else
        msg_output+="✅ Charts Helm valides."
      fi
    fi
    break
  fi
done
if [[ "$VSCODE_GIT_COMMAND" = "" ]]; then
  echo -e "${msg_output}"
fi