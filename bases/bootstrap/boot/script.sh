#!/bin/bash

# 1. create sa for bootstrap depolyment.yaml 
# oc create sa bootstrap -n default
#  oc adm policy add-cluster-role-to-user cluster-admin serviceaccount:default:bootstrap
# Infrastructure Nodes
infraNodes="{$2}"

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


clientSecret="${1}"
# convert to base64 for kubesealer
identitySecret=$(echo ${clientSecret} |base64)
# Create kube sealed secrets for sensitive items 
# touch done /run/done and invoke from outside of pod
# pull file over and continue parent script 
cd /${project}/bases/bootstrap/identitySecret

# Install ArgoCD
cd /${project}/overlays/default/argocd 
kustomize build ./ --reorder none | oc apply -f -
#
 while [[ "$(oc get deploy argocd-operator -o template --template='{{ .status.availableReplicas }}' -n argocd)" < 1 ]]
 do 
    echo "Waiting for operator to become available"
 done;

# Install argo applications to start syncing
cd /${project}/overlays/argocd 
kustomize build ./ --reorder none | oc apply -f -

#Label infra nodes & remove worker
oc label nodes ${infraNodes} node-role.kubernetes.io/infra= node-role.kubernetes.io/worker- 

