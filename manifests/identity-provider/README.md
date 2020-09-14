# Configuration
- create a file clientSecrt in the correct overlay directory, add the google credentials for IDP
  - `echo -n  'Secret' > overlays/lab/clientSecret`
- edit `google-oauth-cr.yaml`
  - changed googleID


# Apply
- `oc apply -f overlays/lab/argocd-app-idp-lab.yaml
