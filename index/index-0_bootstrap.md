


# Disclosure

This repository is a personal space to share technical ideas, notes, and experiments. The content reflects my own views and understanding, and should not be taken as the official position of my employer. Please feel free to explore, adapt, and use what is helpful for your own work.

# Cert-Manager Operator

Deploys the cert-manager Operator along with a sample ClusterIssuer making use of same CA certificate.
Dependencies

    None

Details

ACM Minimal Version: 2.14

Documentation: latest

Notes:

    ClusterIssuer is using a self-signed CA file. Production environments should use an appropriate PKI
    Policy configures cluster-monitoring to scrape cert-manager. There are no rules or alerts, only the ServiceMonitor to scrape cert-manager
    Configures cert-manager to include the cluster trusted-ca bundle. This shouldn't hurt if you don't have a ca applied through the cluster-proxy.
    Requires 2.14 to make use of the fail function when there are no deployments to cert-manager namespace.




# Introduction

This repository demonstrates how to use RH ACM together with GitOps and PolicyGenerator to deploy policies to selected spoke clusters.


# Prerequisites

Before using this repository, make sure you have:
- A running OpenShift cluster with Red Hat ACM installed.
- One spoke clusters already imported into ACM. This repo expects that one cluster is named prod-cluster, besides the local-cluster/ACM HUB cluster

# LAB Architecture 

The enviremont has 3 clusters, with the following naming: 
- local-cluster: this is the ACM HUB cluster (cluster where ACM is installed)
- prod-cluster: spoke cluster. For placement porpuses will be labeled with environment: prod


# Configuration

1. Login to ACM HUB cluster

    ```bash
    oc login -u <user> -p <password> <API_ENDPOINT>
    ```

2. Clone Git
    
    ```
    git clone https://github.com/luisevm/acm-gitops-demo
    ```

3. Install Openshift-Gitops in ACM HUB cluster

    ```bash
    oc create -f bootstrap/gitops/00-namespace.yaml
    oc create -f bootstrap/gitops/10-operatorgroup.yaml
    oc create -f bootstrap/gitops/20-subscription.yaml
    ```
    #Check that the installation was successful
    ```bash
    oc -n openshift-gitops-operator get csv
    ```

4. Give RBAC to allow the user you login to OpenShift or ArgoCD, to see in ArgoCD the applications created in ACM HUB OpenShift cluster. Replace the user "Admin" with your user.

    ```bash
    oc create -f - <<EOF
    apiVersion: user.openshift.io/v1
    kind: Group
    metadata:
      name: cluster-admins
    users:
    - admin
    EOF
    ```

5. Configure ArgoCD instance to use the PolicyGenerator plugin.

???
. Note that in order for ArgoCD to not constantly delete this distributed policy or show that the ArgoCD Application is out of sync, the following parameter value was added to the kustomization.yaml file to set the IgnoreExtraneous option on the policy:
commonAnnotations:
  argocd.argoproj.io/compare-options: IgnoreExtraneous
???

@@@@@@@@@@@@@@

    In order for OpenShift GitOps to have access to the policy generator when you run Kustomize, an Init Container is required to copy the policy generator binary from the RHACM Application Subscription container image to the OpenShift GitOps container that runs Kustomize. Additionally, OpenShift GitOps must be configured to provide the --enable-alpha-plugins flag when you run Kustomize. 

    Documentation reference link: [Integrating the Policy Generator with OpenShift GitOps](https://docs.redhat.com/en/documentation/red_hat_advanced_cluster_management_for_kubernetes/2.13/html/gitops/gitops-overview#integrate-pol-gen-ocp-gitops) and [chapter](https://docs.redhat.com/en/documentation/red_hat_advanced_cluster_management_for_kubernetes/2.13/html/gitops/gitops-overview#gitops-policy-definitions).


    a. Find the imageContainer version for your ACM version:
    - Open https://catalog.redhat.com
    - Search by image multicluster-operators-subscription
    - Check the image versions available and select the image name that match your ACM version, in my case ACM version is 2.14 and the correspondent image is: registry.redhat.io/rhacm2/multicluster-operators-subscription-rhel9:v2.14
    
    b. Patch the ArgoCD adding the following configuration to the existing ArgoCD manifest:
    - Edit the patch file and customize the image name
    
        ```bash
        #replace the image
        vi bootstrap/gitops/30-argocd-patch.yaml
        ```
    - Patch ArgoCD, to configure OpenShift GitOps:
        ```bash
        oc -n openshift-gitops patch argocd openshift-gitops --type=merge --patch-file bootstrap/gitops/30-argocd-patch.yaml
        ```

    c. Check that the ArgoCD instance restarts and that is goes running again, pod "openshift-gitops-repo-server"

    ```
    oc -n openshift-gitops get pods
    ```

6. Bootstrap required Objects

    a. Create in ACM HUB the namespace where the Policyes will be saved 

    ```
    oc create -f bootstrap/clustergroups/00-namespace.yaml
    ```

    b.Configure the RBAC

    ```
    oc create -f bootstrap/clustergroups/10-rbac.yaml
    ```

    c.

    ```
    oc create -f bootstrap/clustergroups/30-mce-mceprod.yaml
    ```

    d.
    ```
    oc create -f bootstrap/clustergroups/31-mce-mcedev.yaml
    ```

    e.
    ```
    oc label managedcluster prod-cluster cluster.open-cluster-management.io/clusterset=mceprod --overwrite
    oc label ManagedCluster prod-cluster environment=prod
    #oc create -f bootstrap/clustergroups/40-mc-mcprod.yaml
    ```

    f.
    ```
    oc label managedcluster dev-cluster cluster.open-cluster-management.io/clusterset=mcedev --overwrite
    oc label ManagedCluster dev-cluster environment=dev
    #oc create -f bootstrap/clustergroups/41-mc-mcdev.yaml 
    ```

    g.
    ```
    oc create -f bootstrap/clustergroups/50-mcsb-mceprod.yaml 
    ```

    h.
    ```
    oc create -f bootstrap/clustergroups/51-mcsb-mcedev.yaml
    ```

    i.
    ```
    #oc create -f bootstrap/clustergroups/10-rbac-allow-argocd-recreation-objs.yaml
    ```

    j.
    ```bash
    #(Required for the RedHat demo platform) - Give admin user the permitions to create policies with the policyGenerator
    cat << EOF | oc apply -f -
    apiVersion: rbac.authorization.k8s.io/v1
    kind: ClusterRoleBinding
    metadata:
      name: open-cluster-management:subscription-admin
    roleRef:
      apiGroup: rbac.authorization.k8s.io
      kind: ClusterRole
      name: open-cluster-management:subscription-admin
    subjects:
    - apiGroup: rbac.authorization.k8s.io
      kind: User
      name: kube:admin
    - apiGroup: rbac.authorization.k8s.io
      kind: User
      name: system:admin
    - apiGroup: rbac.authorization.k8s.io
      kind: User
      name: admin
    EOF
    ```

#7.Create Placements

    #a.
    ```
    #oc create -f bootstrap/placements/placement.yml
    ```

    #b. 

    ```
    #oc create -f bootstrap/placements/policyset.yml
    ```

    #c. 

    ```
    #oc create -f bootstrap/placements/placementbinding.yml
    ```

8. Create Application

    a.
    ```
    oc create -f app/application2.yml
    ```

    b. Check that the Aplication was created

    ```
    oc -n openshift-gitops get applications.argoproj.io appset-spoke-policies
    ```

# Troubleshoot
Example to troubleshoot the Policy to audit the presence of the OpenShift-Gitops operator.

1. On the ACM HUB cluster

    ```bash
    oc -n acm-policies get policy
    oc -n acm-policies describe policy <...>
    ```

    ```bash
    oc -n acm-policies get policy,placement,placementbinding
    ```

    #Verify that ApplicationSet was deployed
    ```bash
    oc -n openshift-gitops describe application
    ```

    #Verify Applications are created for each policy:

    ```bash
    oc -n openshift-gitops get applications.argoproj.io
    ```

    ```bash
    oc -n acm-policies get placement
    oc -n acm-policies describe placement gitops-targets
    ```

    ```bash
    oc -n acm-policies get placementdecision
    ```

    ```bash
    oc -n acm-policy describe policy <your-policy-name>
    oc -n prod-cluster get policy
    ```

2. On the spoke cluster

    #Verify Policy was propagated to the spoke cluster
    ```bash
    oc -n prod-cluster get policy
    oc -n prod-cluster describe policy <...>
    ```

    #Look at policy-controller logs on the spoke
    ```bash
    oc -n open-cluster-management-agent-addon get pods | grep governance-policy-framework
    oc -n open-cluster-management-agent-addon logs <policy-framework-pod>
    ```
