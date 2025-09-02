#!/bin/bash

exec_bash(){
  kubectl exec -t -i ${1} -- /bin/bash
}

exec_shell(){
  kubectl exec -t -i ${1} -- /bin/shell
}

exec_bash_completion() {
  if (( $# < 2 )); then
    klaas_get_pods "$@"
  fi
}

exec_shell_completion() {
  if (( $# < 2 )); then
    klaas_get_pods "$@"
  fi
}

register_klaas_extension "exec" "bash"
register_klaas_extension "exec" "shell"