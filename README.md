

-     

> This repository contains manifests to configure OpenShift 4 clusters with ArgoCD.  Detailed below is a guide illustrating how this works.

  

## Demo Environment

![](https://lh6.googleusercontent.com/ABAkXx1kfN1X-Q4sDOk31V94bi7q0Zt7UtuxA_GA-owcV5D7eqr37QuDUqXNH27PRtc3PKbZ4IAqBmkW5lfNsSTVfEbVRxjbT9Qr-ar8cv8LIM6kITp1r0x_slG8CGR6_PzKwyHj)
1.    
    
## Pre-Reqs


### Sealed Secrets

Kubeseal is the CLI for sealed secrets and can be installed below.

#### Linux

	wget https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.12.5/kubeseal-linux-amd64 -O kubeseal

	sudo install -m 755 kubeseal /usr/local/bin/kubeseal

#### Mac

    brew install kubeseal

### ArgoCD CLI

  - Download [argocd](https://argoproj.github.io/argo-cd/getting_started/#2-download-argo-cd-cli) cli,  this will be used to managed argocd and for the purposes of this demo import additional clusters.
  
### Notes:

-   When creating secrets the base64 encoded secret may different with \n (newline) if you don’t createthe secret to a file correctly, (echo -n).
    

-   `echo -n “clienSecret” > overlays/lab/clientSecret`
    

-   [Creating Second CLuster](https://argoproj.github.io/argo-cd/getting_started/#5-register-a-cluster-to-deploy-apps-to-optional)
    


    
-   argocd cluster add <context from kubeconfig>
    
-   INFO[0000] ServiceAccount "argocd-manager" created in namespace "kube-system" ### This is on the cluster being imported into argoCD
    
-   INFO[0000] ClusterRole "argocd-manager-role" created
    
-   INFO[0000] ClusterRoleBinding "argocd-manager-role-binding" created
    

#### Lab

-   Argocd is installed
    

-   Deploying argocd applications requires the context to be this CLUSTER
    

-   SealedSecrets is installed
    
-   Uses NFS for registry
    
-   No Infrastructure Nodes
    

#### Dev

-   SealedSecrets is installed
    
-   Uses block device for registry , replicas 1
    
-   Has 2 infrastructure nodes
    
-   Migrating infrastructure workloads
    

-   Registry
    
-   Router
    
-   Monitoring
    

  
  
  
  


#### Notes

-   There will be two installations of Sealed Secrets for this demo, lab and demo.  
    “Lab” cluster :
    

oc config use-context lab

oc get secret -n kube-system -l sealedsecrets.bitnami.com/sealed-secrets-key -o yaml > master.yaml

-   I then installed this master.yaml on the “Dev” cluster which creates a secret used to decrypt SealedSecrets. This enables us to use the same sealed secrets on both clusters as the keys are the same.
    

“Dev” cluster:

oc config use-context dev

oc apply -f master.yaml

  
  

Git clone [git@github.com](mailto:git@github.com):hornjason/argocd-lab.git

Git checkout demo

  
  
  
  
  
  
  

### ArgoCD

-   Diagram of what we are trying to achieve
    
-   Update readme.md on argocd-lab
    

#### Bootstrap ArgoCD

##### Deploy argocd-bootstrap

oc config set-context lab

oc apply -k manifests/argocd/argocd-bootstrap

-   Show ArgoCD Operator deployed in OCP
    

  

### Sealed Secrets

Install Sealed Secrets on all clusters, this will allow storing secrets in source control.

#### Deploy Lab

To re-use a sealedsecret key encrypted from a prior version you can apply it before installing. For the purposes of this demo we will start from scratch.

oc config use-context lab

oc apply -f manifests/sealed-secrets/overlays/lab/argocd-app-sealedsecrets.yaml

-   Grab SealedSecret KEY, you’ll want to back this up so you can unseal secrets that use this key later.
    

oc get secret -n kube-system -l sealedsecrets.bitnami.com/sealed-secrets-key -o yaml > master.yaml

#### Deploy Dev

oc config use-context dev

oc apply -f master.yaml

oc config use-context lab

oc apply -f manifests/sealed-secrets/overlays/dev/argocd-app-sealedsecrets.yaml

### Second Cluster

argocd login --sso $(oc get route -o jsonpath='{.items[*].spec.host}' -n argocd)

-   Add context to kubeconfig for second cluster
    

export=/Users/jhorn/projects/git/tech-ready/vsphere-ipi/hub/auth/kubeconfig

oc config get-contexts

oc login -u <login> https://api.cluser.domain.name:6443

-   A new context is added
    

Oc config get-contexts; oc config rename-context <old> <new friendly name>

argocd cluster add; # lists the contexts out

argocd cluster add < context of second clusters friendly name>

-   argocd cluster add dev
    

  

### Identity Provider (google example)

-   Tree manifests/identity-provider
    
-   Describe what we are creating / doing. Creating google idp
    

#### Lab

-   Demonstrate there are no IDPs configured
    
-   oc get oauth cluster -o yaml
    

##### Deploy

-   echo -n “clientSecretRaw” | oc create secret generic idp-secret --dry-run --from-file=clientSecret=/dev/stdin -o yaml | kubeseal - -o yaml>/run/idp_sealed_secret.yaml
    
-   oc apply -f manifests/identity-provider/overlays/lab/argocd-app-idp-lab.yaml
    

  

Verify Secret is correctly configured using secretGenerator

-   oc get secrets -n openshift-config idp-secret -o=jsonpath="{.data.clientSecret}"|base64 -d
    

-   Login using IDP
    

-   Should see appropriate IDP screen.
    

#### Dev

-   Demonstrate there are no IDPs configured
    
-   oc get oauth cluster -o yaml
    

##### Deploy

-   echo -n “clientSecretRaw” | oc create secret generic idp-secret --dry-run --from-file=clientSecret=/dev/stdin -o yaml | kubeseal - -o yaml>/run/idp_sealed_secret.yaml
    
-   oc apply -f manifests/identity-provider/overlays/dev/argocd-app-idp-dev.yaml
    

  

Verify Secret is correctly configured using secretGenerator

-   oc get secrets -n openshift-config idp-secret -o=jsonpath="{.data.clientSecret}"|base64 -d
    

-   Login using IDP
    

-   Should see appropriate IDP screen.
    

-     
    

  
  

#### Create ArgoCD instance

-   Describe tree of argocd directory
    
-   Describe base / overlays
    

##### Deploy ArgoCD instance

oc apply -k manifests/argocd/overlays/lab

clusterrolebinding.rbac.authorization.k8s.io/argocd-application-controller-cluster-admin created

argocd.argoproj.io/example-argocd created

group.user.openshift.io/argo-admins created

  
  

-   Show route created from overlays
    

oc get route -o jsonpath='{.items[*].spec.host}' -n argocd

-   Demonstrate argo-admins group created for RBAC Controls
    

oc describe groups argo-admins

-   Access ArgoCD GUI login with OCP and demo no apps created
    

  
  
  

### Cluster Users

-   Tree manifests/cluster-users
    
-   Describe what we are creating / doing. Creating cluster-users with 2 users
    

#### Lab

-   oc config use-context lab
    
-   oc get clusterrolebindings.rbac cluster-users (doesn’t exist)
    

##### Deploy

-   oc apply -f manifests/cluster-users/overlays/lab/argocd-app-clusterusers-lab.yaml
    
-   oc describe clusterrolebindings.rbac cluster-users
    
-   Matches what's described in kustomize.
    

#### Dev

-   oc config use-context dev
    
-   oc get clusterrolebindings.rbac cluster-users (doesn’t exist)
    

##### Deploy

-   oc config use-context lab
    
-   oc apply -f manifests/cluster-users/overlays/dev/argocd-app-clusterusers-dev.yaml
    
-   oc describe clusterrolebindings.rbac cluster-users -o yaml
    
-   Matches what's described in kustomize.
    

### Registry

-   Describe tree of manifest/registry/
    

-   Base is generic
    
-   overlay/<env> is specific for that env.
    

-   Describe purpose, expectations
    

#### LAB (NFS)

-   contents of registry/overlays/lab/
    
-   image-registry cluster operator is degraded , state = removed
    

oc get configs.imageregistry.operator.openshift.io cluster -o=jsonpath="{.spec.managementState}"

oc get co image-registry

##### Deploy

oc apply -f manifests/registry/overlays/lab/argocd-app-registry-lab.yaml

-   Show ArgoCD now has a new application
    
-   Show image-registry cluster operator running
    

oc get co image-registry

oc get configs.imageregistry cluster -o=jsonpath="{.spec.managementState}"

oc get configs.imageregistry cluster -o=jsonpath="{.spec.storage}"

-   Show there is no registry PV, PVC
    

-   oc get pv
    
-   oc get pvc -n openshift-image-registry
    

  

#### Dev (Block)

oc config use-context dev

-   Show contents of registry/overlays/dev/
    
-   image-registry cluster operator is degraded , state = removed
    

oc get configs.imageregistry.operator.openshift.io cluster -o=jsonpath="{.spec.managementState}"

oc get co image-registry

##### Deploy

oc config use-context lab

oc apply -f manifests/registry/overlays/dev/arqocd-app-registry-dev.yaml

-   Show ArgoCD now has a new application
    
-   Show image-registry cluster operator is not degraded/storage attached
    

oc config use-context dev

oc get co image-registry

oc get configs.imageregistry cluster -o=jsonpath="{.spec.managementState}"

oc get configs.imageregistry cluster -o=jsonpath="{.spec.storage}”

-     
    
-   Show there is no registry PV, PVC
    

oc get pv

oc get pvc -n openshift-image-registry

-   #### The “Dev” cluster contains infrastructure nodes so the overlay for dev updates the registry CR adding a toleration and nodeselector.
    

oc get po -o wide -n openshift-image-registry

  
  
  
  

##### Migrate Metrics

-   Since the “Dev” cluster contains infrastructure nodes we will move metrics pods to those nodes with tolerations and nodeselectors using the overlay for dev.
    

oc config use-context dev

oc get nodes

oc get po -o wide -n openshift-monitoring

  

#### Deploy

oc config use-context lab

oc apply -f manifests/migrate-metrics/overlays/dev/argocd-app-migratemetrics-dev.yaml

  

Verify

oc config use-context dev

oc get po -o wide -n openshift-monitoring

  

#### Migrate Router

-   Since the “Dev” cluster contains infrastructure nodes we will move router pods to those nodes with tolerations and nodeselectors using the overlay for dev.
    

oc config use-context dev

oc get po -o wide -n openshift-ingress

  

#### Deploy

oc config use-context lab

oc apply -f manifests/migrate-metrics/overlays/dev/argocd-app-migratemetrics-dev.yaml

#### Verify

oc config use-context dev

oc get po -o wide -n openshift-ingress

#### Infra Nodes

-   This manifest sets the default scheduler and create an infra MachineConfigPool
    
-   To create an “Infra” machine set try:
    

-   [https://github.com:christianh814/mk-machineset](https://github.com/christianh814/mk-machineset)
    

#### Deploy

oc config use-context lab

oc apply -f manifests/infra-nodes/overlays/dev/argocd-app-infranodes-lab.yaml

#### Verify

oc config use-context dev

oc get mcp

oc get schedulers.config.openshift.io cluster -o=jsonpath="{.spec}"

<!--stackedit_data:
eyJoaXN0b3J5IjpbLTE1MDk1NjkwOTIsLTEzODQwNzI3NV19
-->