#!/bin/bash

## check : gitleaks
cmd_out=$(git diff --cached --name-only --diff-filter=AM | tar -cf - -T - | docker run --rm -i peekleon/gitleaks-pre-commit:latest 2>&1)
STATUS=$?

if [ $STATUS -ne 0 ]; then
  msg_output_vscode_git+="😱 Fuite de mot de passe détectée\n"
  if [[ "$VSCODE_GIT_COMMAND" != "" ]]; then
    echo -e "${msg_output_vscode_git}"
    echo -e "${cmd_out}"
  else
    echo -e "${cmd_out}"
  fi
  exit 1
fi

