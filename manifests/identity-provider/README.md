# Configuration
- create a file clientSecrt in the correct overlay directory, add the google credentials for IDP
  - `cat "Secret" > overlays/lab/clientSecret`
- edit `google-oauth-cr.yaml`
  - changed googleID


# Apply
- `oc apply -k overlays/lab`
