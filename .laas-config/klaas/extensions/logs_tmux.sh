#!/bin/bash

logs_tmux(){
  NAMESPACE=$(kubectl config view --minify --output 'jsonpath={..namespace}')
  SESSION_NAME=$NAMESPACE

  # DEPLOYMENT=$3

  SPLIT_H_V=$1

  # Start tmux session
  tmux new-session -d -s $SESSION_NAME
  tmux set-option -t "${SESSION_NAME}" pane-border-status top
  tmux set-option -t "${SESSION_NAME}" pane-border-style "fg=blue"

  shift 3

  pods=()
  for DEPLOYMENT in "${@:2}"; do
    # Get selector
    selector=$(kubectl get deployment ${DEPLOYMENT} -n ${NAMESPACE} -o=json | jq -r '.spec.selector.matchLabels | to_entries | map("\(.key)=\(.value)") | join(",")')
    # Get pods
    pods+=($(kubectl get pods -n ${NAMESPACE} -l ${selector} | tail -n +2 | awk '{print $1}'))
  done
  number_pods=${#pods[@]}

  # Initialize an index
  index=0

  # While loop to iterate over the array
  while [ $index -lt $number_pods ]; do
      # Check if it's the first iteration
      if [ $index -gt 0 ]; then

          if [[ "${SPLIT_H_V}" == "v" ]]; then
            # Split window horizontally
            tmux split-window -v -t $SESSION_NAME
            tmux select-layout -t $SESSION_NAME even-vertical
          else
            # Split window horizontally
            tmux split-window -h -t $SESSION_NAME
            tmux select-layout -t $SESSION_NAME even-horizontal
          fi
      fi

      pod=${pods[$index]}
      pane_index="0.$index"

      tmux send-keys -t "${SESSION_NAME}:${pane_index}" "printf '\033]2;Pod : ${pod}\033\\'"
      tmux send-keys -t "${SESSION_NAME}:${pane_index}" C-m
      tmux send-keys -t "${SESSION_NAME}:${pane_index}" "kubectl logs -n ${NAMESPACE} -f ${pod}" C-m
      # Increment the index
      ((index++))
  done



  # # Send command to the first pane
  # tmux send-keys -t "${SESSION_NAME}:0.0" "your_command_for_pane_0" C-m

  # # Send command to the second pane
  # tmux send-keys -t "${SESSION_NAME}:0.1" "your_command_for_pane_1" C-m

  # # Attach to the tmux session
  tmux attach-session -t $SESSION_NAME
}

logs_tmux_vertical() {
    logs_tmux "v" "$@"
}

logs_tmux_horizontal() {
    logs_tmux "h" "$@"
}

logs_tmux_vertical_completion() {
  klaas_get_deployments "$@"
}

logs_tmux_horizontal_completion() {
  klaas_get_deployments "$@"
}

register_klaas_extension "logs" "tmux.vertical"
register_klaas_extension "logs" "tmux.horizontal"