



Cert-Manager Operator

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


-----------------------------------------------
# ACM GitOps Demo - Cert-Manager Operator

This repository demonstrates how to deploy and manage the cert-manager operator using Red Hat Advanced Cluster Management (ACM) GitOps policies. It provides a complete example of deploying cert-manager with monitoring, health checks, and a sample ClusterIssuer configuration.

## Overview

This repository uses ACM's Policy Generator to create GitOps policies that deploy and manage:
- The cert-manager operator from Red Hat operators catalog
- Monitoring configuration for cert-manager metrics
- Health status policies to verify operator deployment
- A sample CA-based ClusterIssuer (for demonstration purposes)

Additionally, this repository includes an ArgoCD ApplicationSet configuration that can automatically discover and manage the policies via ArgoCD, providing an alternative GitOps deployment method.

## Repository Structure

```
operators/
├── apps/
│   └── application.yml              # ArgoCD ApplicationSet for policy management
└── cert-manager/
    ├── kustomization.yaml          # Kustomize configuration
    ├── generator.yml                # Policy Generator definition
    ├── namespace.yml                # Namespace for cert-manager-operator
    ├── operatorpolicy.yml           # OperatorPolicy for cert-manager installation
    ├── trusted-ca-configmap.yml     # Trusted CA configuration
    ├── ca-clusterissuer/            # Sample ClusterIssuer
    │   ├── ca-clusterissuer.yml
    │   ├── ca-clusterissuer-secret.yml
    │   └── README.md
    ├── health/                       # Health check policies
    │   └── cert-manager-status.yml
    ├── monitoring/                   # Prometheus monitoring configuration
    │   ├── namespace.yml
    │   ├── role.yml
    │   ├── rolebinding.yml
    │   └── servicemonitor.yml
    └── README.md
```

## Components

### Policy Generator Configuration (`generator.yml`)

Defines two main policies:

1. **cert-manager-operator**: Installs and configures the cert-manager operator
   - Creates the `cert-manager-operator` namespace
   - Deploys trusted CA configuration
   - Installs the operator via OperatorPolicy
   - Sets up monitoring with ServiceMonitor
   - Configures health status checks (InformOnly)

2. **cert-manager-clusterissuer**: Deploys a sample CA-based ClusterIssuer
   - Creates a secret containing the CA certificate
   - Deploys the ClusterIssuer resource
   - Depends on the cert-manager-operator policy

**PlacementBinding Configuration**: The Policy Generator automatically creates PlacementBindings when processing this configuration. The `placementBindingDefaults` section in `generator.yml` specifies that the generated PlacementBinding will be named `cert-manager-binding`. This binding connects the policies to the placement specified in the policySets section (references `env-bound-placement`).

### OperatorPolicy

Configures the cert-manager operator installation:
- **Channel**: `stable-v1.16`
- **Source**: `redhat-operators` catalog
- **Namespace**: `cert-manager-operator`
- **Remediation**: Enforce (automatic)
- **Upgrade Approval**: Automatic
- Includes trusted CA configuration via environment variable

### Monitoring

Sets up Prometheus monitoring for cert-manager:
- Creates monitoring namespace, role, and role binding
- Configures ServiceMonitor to scrape cert-manager metrics
- Metrics endpoint: `tcp-prometheus-servicemonitor` on port 9402
- Scrape interval: 30 seconds

### Health Checks

The `health/cert-manager-status.yml` file contains a health verification policy that dynamically checks the status of all cert-manager deployments in the `cert-manager` namespace. This policy uses ACM's ConfigurationPolicy with Go template syntax to:

1. **Dynamic Discovery**: Uses the `lookup` function to find all Deployments in the `cert-manager` namespace at evaluation time
2. **Replica Verification**: For each deployment found, verifies that:
   - `readyReplicas` matches the expected replica count
   - `availableReplicas` matches the expected replica count
   - `updatedReplicas` matches the expected replica count
   - All replica counts match `spec.replicas` (defaults to 1 if not specified)
3. **Condition Checks**: Verifies that all deployment conditions have `status: "True"` (e.g., `Available`, `Progressing`, `ReplicaFailure`)
4. **Failure Detection**: If no deployments are found in the `cert-manager` namespace, the policy fails with the error message: "There are zero deployments in cert-manager namespace."

**Key Features**:
- **Dynamic**: Automatically discovers all deployments in the namespace, so it works regardless of how many cert-manager components are deployed
- **Comprehensive**: Checks both replica counts and deployment conditions to ensure full health
- **InformOnly Mode**: Set to `InformOnly` in the generator (remediationAction: InformOnly), meaning it reports compliance status but does not attempt remediation if deployments are unhealthy
- **ACM 2.14+ Requirement**: Uses the `fail` function which requires ACM version 2.14 or higher

This policy ensures that cert-manager is not just installed, but actually running and healthy with all expected replicas available.

### ArgoCD ApplicationSet (`apps/application.yml`)

The `operators/apps/application.yml` file defines an ArgoCD ApplicationSet that provides an alternative method for managing and deploying the cert-manager policies via ArgoCD. This ApplicationSet:

1. **Automatic Discovery**: Uses a Git generator to automatically discover directories matching `operators/cert-manager/*` pattern
2. **Dynamic Application Creation**: Creates ArgoCD Applications for each matching directory, using the directory name as the application name
3. **ACM Integration**: Includes ACM-specific annotations (`apps.open-cluster-management.io/ocm-managed-cluster` and `apps.open-cluster-management.io/ocm-managed-cluster-app-namespace`) to make the applications visible in the ACM Applications UI
4. **Automated Sync**: Configured with automated synchronization that includes:
   - **Prune**: Automatically deletes resources removed from Git
   - **SelfHeal**: Automatically syncs when drift is detected
   - **CreateNamespace**: Automatically creates the destination namespace if it doesn't exist
5. **Deployment Target**: Deploys to the ACM hub cluster (`local-cluster`) in the `acm-policies` namespace

**Configuration Details**:
- **ApplicationSet Name**: `appset-spoke-policies`
- **Namespace**: `openshift-gitops` (where ApplicationSet and generated Applications are created)
- **Destination Namespace**: `acm-policies` (where policy resources are deployed)
- **Project**: `default` ArgoCD project
- **Sync Policy**: Automated with pruning and self-healing enabled

**Usage**: Apply this ApplicationSet to your ArgoCD instance to automatically manage the cert-manager policies. The ApplicationSet will discover the `cert-manager` directory and create an ArgoCD Application to manage it, making it visible in both ArgoCD and ACM Applications UI.

## Requirements

- **ACM Version**: 2.14 or higher (required for `fail` function in health checks)
- Red Hat OpenShift Container Platform cluster
- ACM hub cluster configured
- **Placement/PlacementRule** must be created separately and configured before applying these policies (referenced as `env-bound-placement` in generator.yml)
  - This repository does not create placements - they are assumed to exist from previous setup steps
  - Ensure your placement targets the appropriate clusters where cert-manager should be deployed
- **PlacementBinding**: Automatically created by the Policy Generator (named `cert-manager-binding` as specified in `placementBindingDefaults`) - no manual creation required
- **ArgoCD (Optional)**: If using the ApplicationSet approach, ArgoCD must be installed and configured in the `openshift-gitops` namespace

## Usage

### Prerequisites

Before using this repository, ensure you have:

1. **Created a Placement or PlacementRule** in your ACM hub cluster
   - The default placement name expected is `env-bound-placement`
   - This placement should target the clusters where cert-manager should be deployed
   - If using a different placement name, update the reference in `generator.yml`

2. **Configured the appropriate namespace** for policies (default: `acm-policies`)

### Steps

1. **Clone this repository** to your GitOps source of truth location

2. **Verify or Update Placement Reference**: Check that the placement name in `generator.yml` matches your existing placement:
   ```yaml
   placement:
     placementName: "env-bound-placement"
   ```
   If your placement has a different name, update this value accordingly.

3. **Update Policy Namespace**: Modify the `namespace` in `generator.yml` if needed:
   ```yaml
   namespace: acm-policies
   ```

4. **Apply via ACM or ArgoCD**: Choose one of the following deployment methods:
   - **ACM Policy Generator**: Use ACM's GitOps integration or Policy Generator tooling to create the policies and apply them to your managed clusters
   - **ArgoCD ApplicationSet**: Apply the `operators/apps/application.yml` ApplicationSet to your ArgoCD instance to automatically discover and manage the cert-manager policies

## Important Notes

### Production Considerations

⚠️ **CA Certificate**: The included ClusterIssuer uses a **self-signed CA certificate** for demonstration purposes. In production environments, replace this with your organization's PKI infrastructure.

⚠️ **Policy Namespace**: The generator defaults to namespace `acm-policies`. Update this to match your ACM policy namespace configuration.

⚠️ **Placement vs PlacementBinding**:
  - **Placement/PlacementRule**: This repository **does not create placements** - they must be created separately as a prerequisite. The placement `env-bound-placement` (or your custom placement name) must exist before applying these policies. Placements are typically created in separate GitOps repositories or through ACM console, and this repository only references existing placements.
  - **PlacementBinding**: Automatically created by the Policy Generator. The `placementBindingDefaults` section in `generator.yml` specifies the name (`cert-manager-binding`) that will be used for the generated PlacementBinding resource. No manual creation required - the Policy Generator handles this automatically when processing the configuration.

### Monitoring

- The policy configures cluster-monitoring to scrape cert-manager metrics
- No alerting rules are included - only the ServiceMonitor for metrics collection
- The cert-manager namespace is labeled for cluster-monitoring

### Trusted CA

- The configuration includes a trusted CA ConfigMap for cert-manager
- This allows cert-manager to trust your cluster's CA bundle
- Safe to include even if no cluster-proxy CA is configured

### ArgoCD ApplicationSet

⚠️ **Repository URL**: The ApplicationSet references a specific Git repository URL (`https://github.com/luisevm/acm-gitops-demo.git`). Update this to match your actual repository location before applying.

⚠️ **Namespace Configuration**: The ApplicationSet is configured to deploy to `acm-policies` namespace. Ensure this namespace exists or that ArgoCD has permissions to create it (enabled via `CreateNamespace=true` sync option).

⚠️ **ACM Annotations**: The ApplicationSet includes annotations to make applications visible in ACM UI. The `local-cluster` annotation targets the ACM hub cluster - modify if deploying to a different cluster.

## Documentation

- [Cert-Manager Operator for Red Hat OpenShift](https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/security_and_compliance/index#cert-manager-operator-for-red-hat-openshift)
- [ACM Policy Generator](https://access.redhat.com/documentation/en-us/red_hat_advanced_cluster_management_for_kubernetes/)

## License

This is a demo repository. Check with your organization's policies regarding the use and modification of this code.

