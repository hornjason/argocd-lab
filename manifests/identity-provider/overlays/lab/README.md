# Configuration
- Create a file clientSecrt, add the google credentials for IDP
  - `echo -n 'clientSecret' > clientSecret`
- edit `google-oauth-cr.yaml`
  - changed googleID


# Apply
- `oc apply -f overlays/lab/argocd-app-idp-lab.yaml
