#!/bin/bash
# 1. create sa for bootstrap depolyment.yaml 
# oc create sa bootstrap -n default
#  oc adm policy add-cluster-role-to-user cluster-admin serviceaccount:default:bootstrap

###################
# nameSpace to deploy bootstrap pod
nameSpace="bootstrap"

###################
# Identity Provider Secret
clientSecret="${1}"

###################
# Infrastructure Nodes
infraNodes="{$2}"

###################
# Custom Certs
# Full Chain TLS Cert & Key 
tlsCertFile=~/fullchain.cer
tlsKeyFile=~/jasonhorn.io.key

###################
# git information
gitRepo="https://github.com/hornjason/argocd-lab.git"
gitProject="argocd-lab"
gitUser=""
gitPass=""

###################
# DON'T Change for POC
###################
# Create project and SA for bootstrap Pod
oc new-project project ${nameSpace} --display-name="Temp project to run post configuration bootstrap" &&
# this is SA runs the bootstrap pod
oc create sa bootstrap &&
oc adm policy add-cluster-role-to-user cluster-admin serviceaccount:default:bootstrap
# github secret 
oc create secret generic repo-github --from-literal=username="${gitUser}" --from-literal=password="${gitPass}" -n bootstrap
###################
# mount custom certs to mount in bootstrap pod
oc create secret tls tls-custom-cert --cert="${tlsCertFile}" --key="${tlsKeyFile}" -n bootstrap
oc create secret generic idp-secret --from-literal="${clientSecret}" -n bootstrap
###################
# create config map with options to pass into pod

oc create configmaps args  --from-literal=gitrepo="${gitRepo}" --from-literal=nodes="${infraNodes}"
oc create configmaps script  --from-file=../bases/bootstrap/boot/script.sh 
