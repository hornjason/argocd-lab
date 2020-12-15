Table of Contents
=================

   * [Table of Contents](#table-of-contents)
   * [ArgoCD Delarative Lab](#argocd-delarative-lab)
      * [Overview](#overview)
      * [Demo Environment](#demo-environment)
      * [Pre-Reqs / Setup](#pre-reqs--setup)
         * [OpenShift](#openshift)
         * [Sealed Secrets CLI](#sealed-secrets-cli)
            * [Linux](#linux)
            * [Mac](#mac)
         * [OpenShift Authentication](#openshift-authentication)
            * [Additional Notes](#additional-notes)
         * [ArgoCD CLI](#argocd-cli)
            * [Linux](#linux-1)
            * [Mac](#mac-1)
         * [Source Code Retrieval](#source-code-retrieval)
         * [Kustomize](#kustomize)
            * [Linux](#linux-2)
            * [Mac](#mac-2)
         * [Creating Infra Machine Sets](#creating-infra-machine-sets)
         * [K8s Context setup](#k8s-context-setup)
      * [Deployment](#deployment)
         * [ArgoCD](#argocd)
            * [ArgoCD Operator](#argocd-operator)
            * [ArgoCD Bootstrap](#argocd-bootstrap)
            * [Adding an ArgoCD Cluster](#adding-an-argocd-cluster)
         * [Sealed Secrets](#sealed-secrets)
            * [Deploy Lab](#deploy-lab)
            * [Deploy Dev](#deploy-dev)
         * [Identity Provider (google example)](#identity-provider-google-example)
            * [Lab](#lab)
               * [Deploy](#deploy)
               * [Verify](#verify)
            * [Dev](#dev)
               * [Deploy](#deploy-1)
               * [Verify](#verify-1)
         * [ArgoCD instance](#argocd-instance)
            * [Deploy ArgoCD instance](#deploy-argocd-instance)
         * [Cluster Users](#cluster-users)
            * [Lab](#lab-1)
               * [Deploy](#deploy-2)
            * [Dev](#dev-1)
               * [Deploy](#deploy-3)
         * [Registry](#registry)
            * [LAB (NFS)](#lab-nfs)
               * [Deploy](#deploy-4)
               * [Verify](#verify-2)
            * [Dev (Block)](#dev-block)
               * [Deploy](#deploy-5)
               * [Verify](#verify-3)
         * [Migrate Metrics](#migrate-metrics)
            * [Deploy](#deploy-6)
            * [Verify](#verify-4)
         * [Migrate Router](#migrate-router)
            * [Deploy](#deploy-7)
            * [Verify](#verify-5)
         * [Infra Nodes](#infra-nodes)
            * [Deploy](#deploy-8)
            * [Verify](#verify-6)


ArgoCD Delarative Lab
=======================


This repository contains manifests to configure OpenShift 4 clusters with ArgoCD.


## Overview


> This repository contains manifests to configure OpenShift 4 clusters with ArgoCD.  Detailed below is a guide illustrating how this works.	The configurations for OpenShift and Kubernetes can be managed in a declarative fashion. Using GitOps tools, such as ArgoCD, the application and management of these manifests can by applied in an automated fashion. 



This exercise will introduce several approaches for managing an OpenShift environment in a declarative fashion and make use of the folowing tools:

* [ArgoCD](https://argoproj.github.io/argo-cd/) - Declarative, GitOps tool for Kubernetes.
* [Sealed Secrets](https://github.com/bitnami-labs/sealed-secrets) - 
* [Kustomize](https://github.com/kubernetes-sigs/kustomize) - Tool for managing and generating Kubernetes YAML files.



## Demo Environment


The following diagram depicts the target environment

![](https://documents.app.lucidchart.com/documents/7e70c17a-2110-4e53-9e65-3b2727e8f475/pages/0_0?a=991&x=219&y=103&w=902&h=814&store=1&accept=image%2F*&auth=LCA%20cf46c0435508c81350eb1583031db09cca6046bc-ts%3D1600293951)
|  | Lab | Dev |
|--|--|--|
| Domain | hub.foo.bar | managed.foo.bar |
| Worker Nodes | 3 | 3 |
| Infra Nodes |0 | 2 |
| ArgoCD| X | |
| Sealed Secrets| X | X | 
| Identity Provider | Google | Google |
| Cluster Users | X | X |
| Registry| NFS (RWX) | Block (RWO) | 
| Infra Node |  | X |
| Metrics| | X | 
| Router | | X | 
| | | |   

## Pre-Reqs / Setup


The following configuration and software is required to be installed on your machine prior to beginning the exercises. 

### OpenShift

Two (2) OpenShift 4 clusters are required for this exercise. The first step is download and install the version of the [OpenShift CLI](https://try.openshift.com/). 

Once the OpenShift CLI has been installed, login to the two clusters and rename their context to `dev` and `lab`. This will allow for easy reference when working through the exercise. 

Login to the cluster designated as _dev_ and rename the Kubernetes context to `dev`:

```
oc config rename-context $(oc config current-context) dev
```

Next, login to the cluster designated as lab and rename the Kubernetes context to `lab`:

```
oc config rename-context $(oc config current-context) lab
```

Change back to the _dev_ cluster which will be used to begin the exercises:

```
oc config use-context dev
```

### Sealed Secrets CLI
Sealed Secrets allows for encrypting Kubernetes [Secrets](https://kubernetes.io/docs/concepts/configuration/secret/) so that it can be stored public repositories.  

Kubeseal is the CLI for Sealed secrets and can be installed using one of the methods below.

#### Linux

```
wget https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.12.5/kubeseal-linux-amd64 -O kubeseal
sudo install -m 755 kubeseal /usr/local/bin/kubeseal
```

#### Mac

```brew install kubeseal```



### OpenShift Authentication
OpenShift provides a pluggable identity provider mechanism for securing access to the cluster. In this exercise, we will use the [Google identity provider](https://docs.openshift.com/container-platform/latest/authentication/identity_providers/configuring-google-identity-provider.html). 

Follow the steps to configure a [Google OpenID Connect Integration](https://developers.google.com/identity/protocols/OpenIDConnect)

#### Additional Notes
When creating secrets (such as to configure OpenShift Authentication), the base64 encoded secret may be different with \n (newline) if you don’t createthe secret to a file correctly, (echo -n).

```
echo -n “clientSecret” > manifests/identity-provider/overlays/lab/clientSecret
```

### ArgoCD CLI
ArgoCD emphasizes many [GitOps](https://www.weave.works/technologies/gitops/) principles by using a Git repository as a source of truth for the configuration of Kubernetes and OpenShift environments.  


[Download the ArgoCD CLI](https://argoproj.github.io/argo-cd/getting_started/#2-download-argo-cd-cli) which wil be used later on in the exercises for managing multiple clusters.


#### Linux
```
https://github.com/argoproj/argo-cd/releases/latest
```

#### Mac
```
brew install argocd
```

### Source Code Retrieval

In order to begin this exercise, clone the repository to your local machine

```
git clone https://github.com/hornjason/argocd-lab
cd argocd-lab
```

### Kustomize

[Kustomize](kustomize.io) introduces a template-free way to customize application configuration that simplifies the use of off-the-shelf applications. Now, built into `kubectl`  & `oc` as `apply -k`.

#### Linux
```
curl -s "https://raw.githubusercontent.com/\
kubernetes-sigs/kustomize/master/hack/install_kustomize.sh"  | bash
```

#### Mac
```
brew install kustomize
```


### Creating Infra Machine Sets
Sample Infra Machine set Taint used

```
taints:
- effect: NoSchedule
  key: node-function
  value: infra
```

Infra Node machineset generator can be found here:
```https://github.com/christianh814/mk-machineset```

Run ```oc get -o jsonpath='{.status.infrastructureName}{"\n"}' infrastructure cluster``` to get the cluster-id to use.

### K8s Context setup
Example setup using above architecture and domain names is shown below, adjust as needed.
```
export KUBECONFIG=/path/to/kubeconfig
oc config get-contexts
```
| CURRENT | NAME | CLUSTER | AUTHINFO | NAMESPACE |
|--|--|--|--|--|
| * | openshift-image-registry/api-hub-foo-bar:6443/system:admin | api-hub-foo-bar:6443 | system:admin|openshift-image-registry|

```
oc config rename-contexts openshift-image-registry/api-hub-foo-bar:6443/system:admin lab

oc login -u kubeadmin api.managed.foo.bar:6443
oc config get-contexts
```
| CURRENT | NAME | CLUSTER | AUTHINFO | NAMESPACE |
|--|--|--|--|--|
| * |openshift-image-registry/api-managed-foo-bar:6443/kube:admin | api-managed-foo-bar:6443 | kube:admin|   openshift-image-registry
```
 oc config rename-context  openshift-image-registry/api-managed-foo-bar:6443/kube:admin dev
 oc get contexts
 ```
 | CURRENT | NAME | CLUSTER | AUTHINFO | NAMESPACE |
|--|--|--|--|--|
|* | dev | api-managed-foo-bar:6443 | kube:admin |
| | lab | api-hub-foo-bar:6443 | system:admin  | openshift-image-registry |

## Deployment

With the prerequisites complete, lets work through the exercises in the sections below

### ArgoCD
  
#### ArgoCD Operator

The deployment of ArgoCD can be facilitated through the use of the ArgoCD operator.

Ensure that you are using the _lab_ contextt and deploy the ArgoCD Operator on the "Lab" cluster

```
oc config use-context lab
oc apply -k manifests/argocd/argocd-operator/
```

Note: You may need to run the `oc apply` command more than once due to a race condition in the `ArgoCD` resource being registered to the cluster.

A new namespace called `argocd` will be created with the operator deployed. Confirm the namespace and operator were created and deployed:

#### ArgoCD Bootstrap
- Create the initial ArgoCD instance
```
oc apply -k manifests/argocd/overlays/bootstrap
```
```
oc get pods -n argocd
```
#### Adding an ArgoCD Cluster

With ArgoCD deployed, it is automatically configured to manage the cluster it is deployed within. To manage our _dev_ cluster, we will need to [add a new cluster to ArgoCD](https://arßoproj.github.io/argo-cd/getting_started/#5-register-a-cluster-to-deploy-apps-to-optional).

Login to ArgoCD 
```
argocd --insecure --grpc-web login $(oc get route -o jsonpath='{.items[*].spec.host}' -n argocd) --username admin --password $(oc get secret example-argocd-cluster -o jsonpath="{.data.admin\.password}"|base64 -d)
```

Add the _dev_ cluster to ArgoCD:


```
argocd cluster add dev
```	 


### Sealed Secrets


#### Deploy Lab

To re-use a Sealed Secret key encrypted from a prior version you can apply it before installing. For the purposes of this demo we will start from scratch.
```

oc config use-context lab
oc apply -f manifests/sealed-secrets/overlays/lab/argocd-app-sealedsecrets.yaml
```
Grab Sealed Secret KEY. You will want to back this up so you can unseal secrets that use this key later.
```
oc get secret -n kube-system -l sealedsecrets.bitnami.com/sealed-secrets-key -o yaml > master.yaml
```

#### Deploy Dev

Deploy Sealed Secrets on the Dev cluster, applying the master.yaml, ( sealed secret key ) from the Lab cluster.
```
oc config use-context dev
oc apply -f master.yaml
oc config use-context lab
oc apply -f manifests/sealed-secrets/overlays/dev/argocd-app-sealedsecrets.yaml
```

### Identity Provider (google example)
By default, OpenShift includes a default administrative user (`kubeadmin`), but to allow others the ability to login, additional identity providers can be added.

In this exercise, we will integrate with the Google OpenID Connect client that was created previously.   

#### Lab

Demonstrate there are no IDPs configured
```
 oc config use-context lab
 oc get oauth cluster -o yaml
```    

##### Deploy
Deploy the google clientSecret as a Sealed Secret and create the ArgoCD application
 ```
echo -n “clientSecretRaw” | oc create secret generic idp-secret --dry-run=client  --from-file=clientSecret=/dev/stdin -o yaml -n openshift-config | kubeseal - -o yaml> manifests/identity-provider/overlays/lab/idp-sealed-secret.yaml

oc apply -f manifests/identity-provider/overlays/lab/argocd-app-idp-lab.yaml
```
    

##### Verify
Verify Secret is correctly configured using secretGenerator
```
oc config use-context lab
		
oc get secrets -n openshift-config idp-secret -o=jsonpath="{.data.clientSecret}"|base64 -d
```

Login using IDP
    
Should see appropriate IDP screen.
    

#### Dev

Demonstrate there are no IDPs configured
```    
oc config use-context dev

oc get oauth cluster -o yaml
```   

##### Deploy
Deploy the google clientSecret as a Sealed Secret and create the ArgoCD application
```
oc config use-context lab

echo -n “clientSecretRaw” | oc create secret generic idp-secret --dry-run=client --from-file=clientSecret=/dev/stdin -o yaml  -n openshift-config  | kubeseal - -o yaml > manifests/identity-provider/overlays/dev/idp-sealed-secret.yaml
    
oc apply -f manifests/identity-provider/overlays/dev/argocd-app-idp-dev.yaml
```

##### Verify
Verify Secret is correctly configured using secretGenerator
```
oc config use-context dev
		
oc get secrets -n openshift-config idp-secret -o=jsonpath="{.data.clientSecret}"|base64 -d
``` 

Login using IDP
   
Should see appropriate IDP screen. 
    

####  ArgoCD instance

Describe tree of argocd directory
    
Describe base / overlays
    

#### Deploy ArgoCD instance
Deploy a ArgoCD instance for this demo will be "example-argocd"
```		
oc config use-context lab
		
oc apply -k manifests/argocd/overlays/lab
```

Show route created from overlays
```   
oc get route -o jsonpath='{.items[*].spec.host}' -n argocd
```

Demonstrate argo-admins group created for RBAC Controls
```    
oc describe groups argo-admins
```
Access ArgoCD GUI login with OCP and demo no apps created
    

### Cluster Users

tree manifests/cluster-users
    
Describe what we are creating / doing. Creating cluster-users with 2 users
    

#### Lab
Check for existing clusterrolebinding 
```
oc config use-context lab
		    
oc get clusterrolebindings.rbac cluster-users # shouldn't exist
```    

##### Deploy
Deploy the ArgoCD application

```
oc config use-context lab
		
oc apply -f manifests/cluster-users/overlays/lab/argocd-app-clusterusers-lab.yaml
		    
oc describe clusterrolebindings.rbac cluster-users
```

Matches what's described in kustomize.
    

#### Dev
Check for existing clusterrolebinding
```		
oc config use-context dev
		    
oc get clusterrolebindings.rbac cluster-users  # shouldn't exist
```    

##### Deploy
Deploy the ArgoCD application
```
oc config use-context lab
		    
oc apply -f manifests/cluster-users/overlays/dev/argocd-app-clusterusers-dev.yaml
# switch contexts
oc config use-context lab
		
oc describe clusterrolebindings.rbac cluster-users 
```    

Matches what's described in kustomize.
    

### Registry

Describe tree of manifest/registry/
   
Describe purpose, expectations
    

#### LAB (NFS)

contents of registry/overlays/lab/
    
image-registry cluster operator is degraded , state = removed

```
oc config use-context lab
		
oc get configs.imageregistry.operator.openshift.io cluster -o=jsonpath="{.spec.managementState}"

oc get co image-registry
```

##### Deploy
Deploy the ArgoCD application
```
oc config use-context lab

oc apply -f manifests/registry/overlays/lab/argocd-app-registry-lab.yaml
```
Show ArgoCD now has a new application
    
Show image-registry cluster operator running
    
##### Verify
Verify registry has been provisioned
```
oc config use-context lab
		
oc get co image-registry

oc get configs.imageregistry cluster -o=jsonpath="{.spec.managementState}"

oc get configs.imageregistry cluster -o=jsonpath="{.spec.storage}"
```

Show registry PV, PVC
```
oc get pv
		 
oc get pvc -n openshift-image-registry
```   

#### Dev (Block)
contents of registry/overlays/dev/
    
image-registry cluster operator is degraded , state = removed
```
oc config use-context dev        

oc get configs.imageregistry.operator.openshift.io cluster -o=jsonpath="{.spec.managementState}"

oc get co image-registry
```

##### Deploy
Deploy the ArgoCD application
```
oc config use-context lab

oc apply -f manifests/registry/overlays/dev/arqocd-app-registry-dev.yaml
```

Show ArgoCD now has a new application
    
Show image-registry cluster operator is not degraded/storage attached
    
##### Verify
Verify registry has been provisioned
```
oc config use-context dev

oc get co image-registry

oc get configs.imageregistry cluster -o=jsonpath="{.spec.managementState}"

oc get configs.imageregistry cluster -o=jsonpath="{.spec.storage}”
```

Show  registry PV, PVC
```
oc get pv

oc get pvc -n openshift-image-registry
```

The “Dev” cluster contains infrastructure nodes so the overlay for dev updates the registry CR adding a toleration and nodeselector.

```
oc get po -o wide -n openshift-image-registry
```

### Migrate Metrics

Since the “Dev” cluster contains infrastructure nodes we will move metrics pods to those nodes with tolerations and node selectors using the overlay for dev.
    
```
oc config use-context dev

oc get nodes

oc get po -o wide -n openshift-monitoring |grep -i infra
```

Take note of any pods residing on infra nodes before migration.
  

#### Deploy
Deploy the ArgoCD application
```
oc config use-context lab

oc apply -f manifests/migrate-metrics/overlays/dev/argocd-app-migratemetrics-dev.yaml
```
  

#### Verify
Verify registry has been provisioned
```
oc config use-context dev

oc get po -o wide -n openshift-monitoring | grep -i infra
```

Notice which pods have migrated to infra nodes. 

### Migrate Router

Since the “Dev” cluster contains infrastructure nodes we will move router pods to those nodes with tolerations and node selectors using the overlay for dev.
```
oc config use-context dev

oc get po -o wide -n openshift-ingress
```

Take note on which nodes the router resides.

  
#### Deploy
Deploy the ArgoCD application
```		
oc config use-context lab

oc apply -f manifests/migrate-router/overlays/dev/argocd-app-migraterouter.yaml
```

#### Verify
Verify router application is provisioned in ArgoCD 
```
oc config use-context dev

oc get po -o wide -n openshift-ingress
```

Pods should now be schedule on infra nodes.

### Infra Nodes

This manifest sets the default scheduler and creates an infra MachineConfigPool
    
To create an “Infra” machine set try:
```
[https://github.com:christianh814/mk-machineset](https://github.com/christianh814/mk-machineset) 
```   

#### Deploy
Deploy the ArgoCD application
```
oc config use-context lab

oc apply -f manifests/infra-nodes/overlays/dev/argocd-app-infranodes-lab.yaml
```

#### Verify
Verify an Infra MachineConfigPool has been created and the cluster scheduler has been updated.
```
oc config use-context dev

oc get mcp

oc get schedulers.config.openshift.io cluster -o=jsonpath="{.spec}"
```

<!--stackedit_data:
eyJoaXN0b3J5IjpbLTIwMDIyMjUzMDUsOTgzMjU1NzY4LC0xMj
M2NjYwODIxXX0=
-->
