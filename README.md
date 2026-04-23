# openshift-sscsi-vault

Helm chart for the [OpenShift Secrets Store CSI Driver](https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html/storage/using-secrets-store-csi-driver) with the **HashiCorp Vault** provider. It aligns hub/spoke Vault addressing and Kubernetes auth mount/role behaviour with the same conventions as a typical **openshift-external-secrets** pattern chart: `https://vault-vault.<hubClusterDomain>`, hub mount `hub` and role `hub-role` on the hub, and spoke mount `<clusterDomain>` with role `<clusterDomain>-role` on spokes.

## Prerequisites

- Secrets Store CSI Driver operator and Vault CSI provider installed on the cluster.
- Vault on the hub configured for Kubernetes auth and roles that match your `ServiceAccount` and namespace.

## Install

```bash
helm upgrade --install sscsi-vault . \
  --namespace your-namespace --create-namespace \
  -f your-values.yaml
```

Pods must use `serviceAccountName` from `ocpSecretsStoreCsiVault.rbac.serviceAccount` and mount a CSI volume with `secretProviderClass` set to `ocpSecretsStoreCsiVault.secretProviderClass.name`.

## Develop

```bash
make test   # helm lint + helm unittest (Podman)
```

## License

Apache 2.0 — see [LICENSE](LICENSE).
