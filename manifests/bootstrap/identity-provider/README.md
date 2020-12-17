# Configuration
## for private / protected repos
- create a file clientSecrt in the correct overlay directory, add the google credentials for IDP
  - `echo -n  'Secret' > overlays/lab/clientSecret`
## for public repos use kubesealer
-  oc create secret generic idp-secret --from-literal=clientSecret="secretgoeshere" --dry-run -n openshift-config -o yaml|kubeseal -o yaml > idp-sealed-secret.yaml

- edit `google-oauth-cr.yaml`
  - changed googleID


# Apply
- `oc apply -f overlays/lab/argocd-app-idp-lab.yaml
