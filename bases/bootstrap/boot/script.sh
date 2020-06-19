#!/bin/bash

# 1. create sa for bootstrap depolyment.yaml 
# oc create sa bootstrap -n default
#  oc adm policy add-cluster-role-to-user cluster-admin serviceaccount:default:bootstrap
# Identity Provider Secret
clientSecret="${1}"

# Infrastructure Nodes
infraNodes="{$2}"


# Full Chaing TLS Cert 
# tlsCertFile=

# TLS Key
# tlsKeyFile=

# git Repository
gitRepo="https://github.com/hornjason/argocd-lab.git"
project="argocd-lab"

# git clone repo 
git clone ${gitRepo}
cd ${project}

# Install Kube Sealer 
# Kubesealer to create sealed secret 
# Push back to git repo
cd overlays/default/kubesealer
kustomize build --reorder none ./ | oc apply -f -# Update Identity Secret
 while [[ "$(oc get deploy sealed-secrets-controller -o template --template='{{ .status.availableReplicas }}' -n argocd)" < 1 ]]
 do 
    echo "Waiting for operator to become available"
 done;

# Create kube sealed secrets for sensitive items 
# touch done /run/done and invoke from outside of pod
# pull file over and continue parent script 
cd /${project}/bases/bootstrap/identitySecret
echo "${clientSecret}" | oc  create secret generic idp-secret \
--from-file=clientSecret=/dev/stdin -o yaml | kubeseal - -o yaml>/run/idp_sealed_secret.yaml

# Create sealed named certs 
# tls.crt & tls.key 
# pass in both file locations tlsKeyFile= tls

# Install ArgoCD
cd /${project}/overlays/default/argocd 
kustomize build ./ --reorder none | oc apply -f -
#
 while [[ "$(oc get deploy argocd-operator -o template --template='{{ .status.availableReplicas }}' -n argocd)" < 1 ]]
 do 
    echo "Waiting for operator to become available"
 done;

# Install argo applications to start syncing
cd /${project}/overlays/lab/argocd 
kustomize build ./ --reorder none | oc apply -f -

#Label infra nodes & remove worker
oc label nodes ${infraNodes} node-role.kubernetes.io/infra= node-role.kubernetes.io/worker- 

