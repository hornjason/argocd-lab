# Creating Second CLuster
Download argocd
argocd cluster add <context from kubeconfig>
# created on remote cluster
INFO[0000] ServiceAccount "argocd-manager" created in namespace "kube-system" 
INFO[0000] ClusterRole "argocd-manager-role" created
INFO[0000] ClusterRoleBinding "argocd-manager-role-binding" created

# Create secret on argocd cluster -n argocd for second cluster 
apiVersion: v1
data:
  {"bearerToken":"","tlsClientConfig":{"insecure":false,"caData":""}
  name: YWRtaW4=
  server: aHR0cHM6Ly9hcGkubWFuYWdlZC5mb28uYmFyOjY0NDM=
kind: Secret
metadata:
  labels:
    argocd.argoproj.io/secret-type: cluster
  name: cluster-api.managed.foo.bar-4077816209
  namespace: argocd
type: Opaque
