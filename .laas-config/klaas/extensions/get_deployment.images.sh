#!/bin/bash

get_deployment_images(){
  deployment_selected=$1
  if [ -n "$1" ]; then
    kubectl get deployment ${deployment_selected} -o json | jq -r --argjson colors "$colors" ' 
      $colors.blue + "\(.metadata.name):\n" + $colors.reset +
      "  Containers:\n" +
      (.spec.template.spec.containers[] | "    - " + $colors.cyan + "\(.name)" + $colors.reset + ": " + $colors.yellow + "\(.image)") + $colors.reset + "\n" +
      "  Init Containers:\n" +
      (if .spec.template.spec.initContainers then
        (.spec.template.spec.initContainers[] | "    - " + $colors.cyan + "\(.name)" + $colors.reset + ": " + $colors.yellow + "\(.image)") + $colors.reset
      else
        $colors.red + "    None" + $colors.reset
      end) + "\n"
    '
  else
    kubectl get deployments -o json | jq -r --argjson colors "$colors" '
      .items[] |
      $colors.blue + "\(.metadata.name):\n" + $colors.reset +
      "  Containers:\n" +
      (.spec.template.spec.containers[] | "    - " + $colors.cyan + "\(.name)" + $colors.reset + ": " + $colors.yellow + "\(.image)") + $colors.reset + "\n" +
      "  Init Containers:\n" +
      (if .spec.template.spec.initContainers then
        (.spec.template.spec.initContainers[] | "    - " + $colors.cyan + "\(.name)" + $colors.reset + ": " + $colors.yellow + "\(.image)") + $colors.reset
      else
        $colors.red + "    None" + $colors.reset
      end) + "\n"
    '
  fi
}

get_deployment_images_completion() {
  klaas_get_deployments "$@"
}

register_klaas_extension "get" "deployment.images"
