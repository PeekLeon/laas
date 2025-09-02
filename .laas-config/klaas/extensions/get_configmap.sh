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