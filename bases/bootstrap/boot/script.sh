############################################################
# below is run on OCP
############################################################
#!/bin/bash

########
# POC
# Passes in args
# $1 = gitRepo
# $2 = Nodes labeled as Infra
# Install Kube Sealer 
# Kubesealer to create sealed secret 
# Push back to git repo

gitRepo="${1}"
infraNodes="${2}"
project="git-temp"

# git clone repo 
git clone ${gitRepo} ${project}

cd /${project}/overlays/default/kubesealer
kustomize build --reorder none ./ | oc apply -f - 
 while [[ "$(oc get deploy sealed-secrets-controller -o template --template='{{ .status.availableReplicas }}' -n argocd)" < 1 ]]
 do 
    echo "Waiting for controller to become available"
 done;

# fetch kubeseal cert
kubeseal --fetch-cert /run/bootstrap/seal.crt

# Create kube sealed secrets for sensitive items 
# touch done /run/bootstrap/done and invoke from outside of pod
# pull file over and deploy.sh parent script 
cd /${project}/bases/bootstrap/identitySecret
oc  create secret generic idp-secret \
--from-file=clientSecret=/run/bootstrap/idp -o yaml | kubeseal - -o yaml>/run/bootstrap/idp_sealed_secret.yaml

# Create sealed named certs 
# tls.crt & tls.key 
# pass in both file locations tlsKeyFile= tls
oc create secret tls custom-certs-default --cert=/run/bootstrap/tlscert/tls.crt --key=/run/bootstrap/tlscert/tls.key -n openshift-ingress \
kubeseal - -o yaml > /run/bootstrap/ingress-default-cert-sealed-secret.yaml
oc create secret tls custom-cert --cert=/run/bootstrap/tlscert/tls.crt --key=/run/bootstrap/tlscert/tls.key -n openshift-config \
kubeseal - -o yaml > /run/bootstrap/apiserver-custom-cert-sealed-secret.yaml

# Install ArgoCD
cd /${project}/overlays/default/argocd 
kustomize build ./ --reorder none | oc apply -f -
#
 while [[ "$(oc get deploy argocd-operator -o template --template='{{ .status.availableReplicas }}' -n argocd)" < 1 ]]
 do 
    echo "Waiting for operator to become available"
 done;

# Install argo applications to start syncing
oc create secret generic repo-github --from-file=username=/run/bootstrap/git/username --from-file=password=/run/bootstrap/git/password -n argocd \
kubeseal - -o yaml > /run/bootstrap/repo-github-sealed-secret.yaml 
cd /${project}/overlays/lab/argocd 
kustomize build ./ --reorder none | oc apply -f -

#Label infra nodes & remove worker
oc label nodes ${infraNodes} node-role.kubernetes.io/infra= node-role.kubernetes.io/worker- 

touch /run/bootstrap/done