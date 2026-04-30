{{/*
Resolve PEM for Vault HTTPS trust (same sources as openshift-external-secrets-chart where applicable).

preset "auto":
  - hub-style cluster (hub or local hashicorp-vault): ConfigMap openshift-ingress/router-ca (ca-bundle.crt)
    so *.apps routes (e.g. vault-vault.apps...) verify like typical OpenShift clients.
  - spoke: Secret external-secrets/hub-ca (hub-kube-root-ca.crt), ACM-synced hub trust (ESO clientCluster).

Requires helm install/upgrade with a live cluster (lookup). If lookup returns nothing, templates omit the sync ConfigMap and vaultCACertPath from sync.
*/}}
{{- define "openshift_sscsi_vault.vaultTlsCaPemFromCluster" -}}
{{- $cap := .Values.ocpSecretsStoreCsiVault.caProvider | default dict }}
{{- $sync := $cap.syncProviderCaConfigMap | default dict }}
{{- if default false $sync.enabled }}
{{- $hashicorp_vault_found := false }}
{{- if and .Values.clusterGroup .Values.clusterGroup.applications }}
{{- range $_, $app := .Values.clusterGroup.applications }}
  {{- if $app }}
    {{- if eq $app.chart "hashicorp-vault" }}
      {{- $hashicorp_vault_found = true }}
    {{- end }}
  {{- end }}
{{- end }}
{{- end }}
{{- $isHubStyleAuth := or (eq (include "openshift_sscsi_vault.ishubcluster" .) "true") $hashicorp_vault_found }}
{{- $preset := $sync.preset | default "auto" | trim | lower }}
{{- if eq $preset "auto" }}
  {{- if $isHubStyleAuth }}
    {{- $preset = "ingressrouterca" }}
  {{- else }}
    {{- $preset = "esospokehubca" }}
  {{- end }}
{{- end }}
{{- if eq $preset "ingressrouterca" }}
  {{- $ref := $sync.ingressRouterCa | default dict }}
  {{- $ns := $ref.namespace | default "openshift-ingress" }}
  {{- $name := $ref.name | default "router-ca" }}
  {{- $key := $ref.key | default "ca-bundle.crt" }}
  {{- $obj := lookup "v1" "ConfigMap" $ns $name }}
  {{- if and $obj (hasKey $obj.data $key) }}{{- index $obj.data $key -}}{{- end }}
{{- else if eq $preset "esohubkuberootca" }}
  {{- $hc := $cap.hostCluster | default dict }}
  {{- $ns := $hc.namespace | default "external-secrets" }}
  {{- $name := $hc.name | default "kube-root-ca.crt" }}
  {{- $key := $hc.key | default "ca.crt" }}
  {{- $obj := lookup "v1" "ConfigMap" $ns $name }}
  {{- if and $obj (hasKey $obj.data $key) }}{{- index $obj.data $key -}}{{- end }}
{{- else if eq $preset "esospokehubca" }}
  {{- $cc := $cap.clientCluster | default dict }}
  {{- $ns := $cc.namespace | default "external-secrets" }}
  {{- $name := $cc.name | default "hub-ca" }}
  {{- $key := $cc.key | default "hub-kube-root-ca.crt" }}
  {{- $obj := lookup "v1" "Secret" $ns $name }}
  {{- if and $obj (hasKey $obj.data $key) }}{{- index $obj.data $key | b64dec -}}{{- end }}
{{- end }}
{{- end }}
{{- end }}

{{- define "openshift_sscsi_vault.syncVaultCsiTlsCaConfigMapYaml" -}}
{{- $cap := .Values.ocpSecretsStoreCsiVault.caProvider | default dict }}
{{- $sync := $cap.syncProviderCaConfigMap | default dict }}
{{- if default false $sync.enabled }}
{{- $pem := trim (include "openshift_sscsi_vault.vaultTlsCaPemFromCluster" .) }}
{{- if ne $pem "" }}
{{- $cmName := $sync.configMapName | default "" | trim }}
{{- if eq $cmName "" }}
{{- $cmName = "openshift-sscsi-vault-vault-tls-ca" }}
{{- end }}
{{- $targetNs := $sync.targetNamespace | default "openshift-cluster-csi-drivers" | trim }}
{{- $keyFile := $sync.keyInConfigMap | default "vault-tls-ca.pem" | trim }}
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ $cmName | quote }}
  namespace: {{ $targetNs | quote }}
  labels:
    app.kubernetes.io/name: openshift-sscsi-vault
    app.kubernetes.io/component: vault-csi-tls-ca
data:
  {{ $keyFile | quote }}: |
{{ $pem | nindent 4 }}
{{- end }}
{{- end }}
{{- end }}
