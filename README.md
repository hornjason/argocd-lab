




-     

> This repository contains manifests to configure OpenShift 4 clusters with ArgoCD.  Detailed below is a guide illustrating how this works.

  

## Demo Environment
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


### Sealed Secrets CLI

Kubeseal is the CLI for sealed secrets and can be installed below.

#### Linux

	wget https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.12.5/kubeseal-linux-amd64 -O kubeseal

	sudo install -m 755 kubeseal /usr/local/bin/kubeseal

#### Mac

    brew install kubeseal

### ArgoCD CLI
ArgoCD CLI allows configuration of argo including importing additional OpenShift clusters.  

#### Linux

    https://github.com/argoproj/argo-cd/releases/latest

#### Mac
```
brew install argocd
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

 ### Code Setup
 - Clone this repository
 
		git clone [git@github.com](mailto:git@github.com):hornjason/argocd-lab.git
		cd argocd-lab
		git checkout demo

### Notes:
#### Sealed Secrets
-   When creating secrets the base64 encoded secret may different with \n (newline) if you don’t createthe secret to a file correctly, (echo -n).
    
	 `echo -n “clienSecret” > manifests/identity-provider/overlays/lab/clientSecret`
    
#### ArgoCD importing clusters
-   [Creating Second CLuster](https://argoproj.github.io/argo-cd/getting_started/#5-register-a-cluster-to-deploy-apps-to-optional)
    
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
  
  ### ArgoCD
  
#### ArgoCD Operator
- Deploy ArgoCD Operator on the "Lab" cluster

		oc config set-context lab

		oc apply -k manifests/argocd/argocd-operator

-   Show ArgoCD Operator deployed in OCP
    
#### ArgoCD Bootstrap
- Create the initial ArgoCD instance
```
	oc apply -k manifests/argocd/overlays/bootstrap
```

### ArgoCD Additional Cluster
- To import additional clusters into ArgoCD, first make sure dex is  a "running" state so --sso will work correctly
```
oc get argocd example-argocd -o=jsonpath="{.status.dex}" -n argocd
```
outputs ```Running```

```
argocd login --sso $(oc get route -o jsonpath='{.items[*].spec.host}' -n argocd)
```
-   Use the "dev" context


		argocd cluster add; # lists the contexts out

		argocd cluster add < context of second clusters friendly name>

		argocd cluster add dev
		    


### Sealed Secrets

Install Sealed Secrets on all clusters, this will allow storing secrets in source control.

#### Deploy Lab

- To re-use a Sealed Secret key encrypted from a prior version you can apply it before installing. For the purposes of this demo we will start from scratch.

		oc config use-context lab

		oc apply -f manifests/sealed-secrets/overlays/lab/argocd-app-sealedsecrets.yaml

-   Grab Sealed Secret KEY, you’ll want to back this up so you can unseal secrets that use this key later.
    
		oc get secret -n kube-system -l sealedsecrets.bitnami.com/sealed-secrets-key -o yaml > master.yaml

#### Deploy Dev
- Deploy Sealed Secrets on the Dev cluster, applying the master.yaml, ( sealed secret key ) from the Lab cluster.

		oc config use-context dev

		oc apply -f master.yaml

		oc config use-context lab

		oc apply -f manifests/sealed-secrets/overlays/dev/argocd-app-sealedsecrets.yaml

  

### Identity Provider (google example)
- To setup credentials and domains to use Google Authentication, vist https://developers.google.com/identity/protocols/oauth2/openid-connect
-   Tree manifests/identity-provider
    
-   Describe what we are creating / doing. Creating google idp
    

#### Lab

-   Demonstrate there are no IDPs configured
```
 oc config use-context lab
 oc get oauth cluster -o yaml
```    

##### Deploy
- Deploy the google clientSecret as a Sealed Secret and create the ArgoCD application
 
		echo -n “clientSecretRaw” | oc create secret generic idp-secret --dry-run=client  --from-file=clientSecret=/dev/stdin -o yam -n openshift-configl | kubeseal - -o yaml> manifests/identity-provider/overlays/lab/idp-sealed-secret.yaml
		
	    oc apply -f manifests/identity-provider/overlays/lab/argocd-app-idp-lab.yaml
    

##### Verify
- Verify Secret is correctly configured using secretGenerator

		oc config use-context lab
		
		oc get secrets -n openshift-config idp-secret -o=jsonpath="{.data.clientSecret}"|base64 -d
    
-   Login using IDP
    

-   Should see appropriate IDP screen.
    

#### Dev

-   Demonstrate there are no IDPs configured
    
		oc config use-context dev

		oc get oauth cluster -o yaml
    

##### Deploy
- Deploy the google clientSecret as a Sealed Secret and create the ArgoCD application

		oc config use-context lab

		echo -n “clientSecretRaw” | oc create secret generic idp-secret --dry-run --from-file=clientSecret=/dev/stdin -o yaml  -n openshift-config  | kubeseal - -o yaml > manifests/identity-provider/overlays/dev/idp-sealed-secret.yaml
    
		oc apply -f manifests/identity-provider/overlays/dev/argocd-app-idp-dev.yaml
    
##### Verify


- Verify Secret is correctly configured using secretGenerator

		oc config use-context dev
		
		oc get secrets -n openshift-config idp-secret -o=jsonpath="{.data.clientSecret}"|base64 -d
    

-   Login using IDP
   
-   Should see appropriate IDP screen. 
    

  
  

####  ArgoCD instance

-   Describe tree of argocd directory
    
-   Describe base / overlays
    

##### Deploy ArgoCD instance
- Deploy a ArgoCD instance for this demo will be "example-argocd"

		
		oc config use-context lab
		
		oc apply -k manifests/argocd/overlays/lab

-   Show route created from overlays
    
		oc get route -o jsonpath='{.items[*].spec.host}' -n argocd

-   Demonstrate argo-admins group created for RBAC Controls
    

		oc describe groups argo-admins

-   Access ArgoCD GUI login with OCP and demo no apps created
    

### Cluster Users

-   Tree manifests/cluster-users
    
-   Describe what we are creating / doing. Creating cluster-users with 2 users
    

#### Lab
- Check for existing clusterrolebinding 

		oc config use-context lab
		    
		oc get clusterrolebindings.rbac cluster-users # shouldn't exist
    

##### Deploy
- Deploy the ArgoCD application
		
		oc config use-context lab
		
		oc apply -f manifests/cluster-users/overlays/lab/argocd-app-clusterusers-lab.yaml
		    
		oc describe clusterrolebindings.rbac cluster-users
    
-   Matches what's described in kustomize.
    

#### Dev
- Check for existing clusterrolebinding
		
		oc config use-context dev
		    
		oc get clusterrolebindings.rbac cluster-users  # shouldn't exist
    

##### Deploy
- Deploy the ArgoCD application

		oc config use-context lab
		    
		oc apply -f manifests/cluster-users/overlays/dev/argocd-app-clusterusers-dev.yaml
		    
	    oc describe clusterrolebindings.rbac cluster-users -o yaml
    
-   Matches what's described in kustomize.
    

### Registry

-   Describe tree of manifest/registry/
   
-   Describe purpose, expectations
    

#### LAB (NFS)

-   contents of registry/overlays/lab/
    
-   image-registry cluster operator is degraded , state = removed
    
		oc config use-context lab
		
		oc get configs.imageregistry.operator.openshift.io cluster -o=jsonpath="{.spec.managementState}"

		oc get co image-registry

##### Deploy
- Deploy the ArgoCD application

		oc config use-context lab

		oc apply -f manifests/registry/overlays/lab/argocd-app-registry-lab.yaml

- Show ArgoCD now has a new application
    
- Show image-registry cluster operator running
    
##### Verify
- Verify registry has been provisioned

		oc config use-context lab
		
		oc get co image-registry

		oc get configs.imageregistry cluster -o=jsonpath="{.spec.managementState}"

		oc get configs.imageregistry cluster -o=jsonpath="{.spec.storage}"

-   Show registry PV, PVC
    
		 oc get pv
		 
	     oc get pvc -n openshift-image-registry
    

  

#### Dev (Block)
-   contents of registry/overlays/lab/
    
-   image-registry cluster operator is degraded , state = removed

		oc config use-context dev        

		oc get configs.imageregistry.operator.openshift.io cluster -o=jsonpath="{.spec.managementState}"

		oc get co image-registry

##### Deploy
- Deploy the ArgoCD application

		oc config use-context lab

		oc apply -f manifests/registry/overlays/dev/arqocd-app-registry-dev.yaml


-   Show ArgoCD now has a new application
    
-   Show image-registry cluster operator is not degraded/storage attached
    
##### Verify
- Verify registry has been provisioned

		oc config use-context dev

		oc get co image-registry

		oc get configs.imageregistry cluster -o=jsonpath="{.spec.managementState}"

		oc get configs.imageregistry cluster -o=jsonpath="{.spec.storage}”

-   Show  registry PV, PVC
    

		oc get pv

		oc get pvc -n openshift-image-registry

-   #### The “Dev” cluster contains infrastructure nodes so the overlay for dev updates the registry CR adding a toleration and nodeselector.
    

		oc get po -o wide -n openshift-image-registry


  

#### Migrate Metrics

-   Since the “Dev” cluster contains infrastructure nodes we will move metrics pods to those nodes with tolerations and node selectors using the overlay for dev.
    
		
		oc config use-context dev

		oc get nodes

		oc get po -o wide -n openshift-monitoring

  

#### Deploy
- Deploy the ArgoCD application

		oc config use-context lab

		oc apply -f manifests/migrate-metrics/overlays/dev/argocd-app-migratemetrics-dev.yaml

  

#### Verify
- Verify registry has been provisioned

		oc config use-context dev

		oc get po -o wide -n openshift-monitoring

  

### Migrate Router

-   Since the “Dev” cluster contains infrastructure nodes we will move router pods to those nodes with tolerations and node selectors using the overlay for dev.
    
		
		oc config use-context dev

		oc get po -o wide -n openshift-ingress

  

#### Deploy
- Deploy the ArgoCD application
		
		oc config use-context lab

		oc apply -f manifests/migrate-metrics/overlays/dev/argocd-app-migratemetrics-dev.yaml

#### Verify
- Verify registry has been provisioned

		oc config use-context dev

		oc get po -o wide -n openshift-ingress

### Infra Nodes

-   This manifest sets the default scheduler and create an infra MachineConfigPool
    
-   To create an “Infra” machine set try:

	-   [https://github.com:christianh814/mk-machineset](https://github.com/christianh814/mk-machineset)
    

#### Deploy
- Deploy the ArgoCD application

		oc config use-context lab

		oc apply -f manifests/infra-nodes/overlays/dev/argocd-app-infranodes-lab.yaml

#### Verify
- Verify an Infra MachineConfigPool has been created and the cluster scheduler has been updated.

		oc config use-context dev

		oc get mcp

		oc get schedulers.config.openshift.io cluster -o=jsonpath="{.spec}"


<!--stackedit_data:
eyJoaXN0b3J5IjpbMTY0MDE3NjIwNywtMTc0ODE1MjU4OSwtOT
k0MjcwMjMsMTkyNjAyNjU0NSwtMTAyNjg4MDExNywtMTU1Mjkx
NjEyNSwtMTYwMDU0MDUwNywtMzExNDk4NjkwLDc1MzAyODc5MS
wxOTAyMjYzNDY2LC0xMjM2NjYwODIxLDQ2MDQ1NTUwOCwtMTM5
MjUwNTk1NywtMTM4NDA3Mjc1XX0=
-->