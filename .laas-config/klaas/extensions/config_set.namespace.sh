
#!/bin/bash

config_set_namespace(){
  kubectl config set-context --current --namespace ${1}
  kubectl get ns "${1}" -o jsonpath='{.metadata.labels}' > /.laas-config/klaas/namespace-label-cache
}

config_set_namespace_completion(){
  klaas_get_namespace
}


register_klaas_extension "config" "set.namespace"