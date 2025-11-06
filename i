ClusterRole		cert-manager-cainjector
ServiceAccount	cert-manager	cert-manager
ClusterRole		cert-manager-cluster-view
ServiceAccount	cert-manager	cert-manager-webhook
ClusterRole		cert-manager-controller-approve:cert-manager-io
ClusterRole		cert-manager-controller-certificatesigningrequests
ClusterRole		cert-manager-controller-challenges
ServiceAccount	cert-manager	cert-manager-cainjector
ClusterRole		cert-manager-controller-certificates
ClusterRole		cert-manager-controller-issuers
ClusterRole		cert-manager-controller-clusterissuers
ClusterRole		cert-manager-controller-orders
ClusterRole		cert-manager-edit
ClusterRole		cert-manager-controller-ingress-shim
Deployment	cert-manager	cert-manager-cainjector
RoleBinding	cert-manager	cert-manager-webhook:dynamic-serving
RoleBinding	kube-system	cert-manager:leaderelection
ClusterRoleBinding		cert-manager-controller-issuers
Role	cert-manager	cert-manager-webhook:dynamic-serving
MutatingWebhookConfiguration		cert-manager-webhook
Deployment	cert-manager	cert-manager
Deployment	cert-manager	cert-manager-webhook
RoleBinding	kube-system	cert-manager-cainjector:leaderelection
Role	cert-manager	cert-manager-tokenrequest
ClusterRoleBinding		cert-manager-controller-approve:cert-manager-io
ClusterRole		cert-manager-view
Role	kube-system	cert-manager-cainjector:leaderelection
Role	kube-system	cert-manager:leaderelection
ClusterRoleBinding		cert-manager-controller-clusterissuers
Service	cert-manager	cert-manager
RoleBinding	cert-manager	cert-manager-cert-manager-tokenrequest
Service	cert-manager	cert-manager-cainjector
Service	cert-manager	cert-manager-webhook
ValidatingWebhookConfiguration		cert-manager-webhook
ClusterRoleBinding		cert-manager-cainjector
ClusterRoleBinding		cert-manager-controller-certificatesigningrequests
ClusterRole		cert-manager-webhook:subjectaccessreviews
ClusterRoleBinding		cert-manager-controller-challenges
Policy	prod-cluster	acm-policies.cert-manager-clusterissuer
Policy	prod-cluster	acm-policies.cert-manager-operator
ClusterRoleBinding		cert-manager-controller-orders
ClusterRoleBinding		cert-manager-controller-certificates
ClusterRoleBinding		cert-manager-webhook:subjectaccessreviews
ClusterRoleBinding		cert-manager-controller-ingress-shim
