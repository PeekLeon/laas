
#!/bin/bash

config_set_namespace(){
  kubectl config set-context --current --namespace ${1}
}

config_set_namespace_completion(){
  klaas_get_namespace
}


register_klaas_extension "config" "set.namespace"