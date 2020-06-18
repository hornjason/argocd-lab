#!/bin/bash

# Infrastructure Nodes
infraNodes="compute-0 compute-1 compute-2"

# git Repository
gitRepo="https://github.com/hornjason/argocd-lab.git"
project="argocd-lab"

# Update Identity Secret
clientSecret="${1}"
# convert to base64 for kubesealer
identitySecret=$(echo ${clientSecret} |base64)
# Create kube sealed secrets for sensitive items
cd /${project}/bases/bootstrap/identity


# git clone repo 
git clone ${gitRepo}
cd ${project}

# Install Kube Sealer 
# Kubesealer to create sealed secret 
# Push back to git repo
cd overlays/default/kubesealer
kustomize build ./ | oc apply -f -

# Install ArgoCD
cd /${project}/overlays/argocd 
kustomize build ./ | oc apply -f -

#Label infra nodes & remove worker
oc label nodes ${infraNodes} node-role.kubernetes.io/infra= node-role.kubernetes.io/worker- 

