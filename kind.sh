#!/bin/bash

# shellcheck source=/dev/null
source credentials

if kind get clusters -q | grep crossplane; then
  kind export kubeconfig --name crossplane
  exit 0
fi

cd "$(dirname "$0")" || exit

cd ..

workspaceDir="$PWD"

cd - > /dev/null || exit

cat <<EOF | kind create cluster --name management --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
networking:
  podSubnet: "10.95.0.0/16"
  serviceSubnet: "10.96.0.0/16"
nodes:
- role: control-plane
  kubeadmConfigPatches:
  - |
    kind: ClusterConfiguration
    controllerManager:
      extraArgs:
        bind-address: 0.0.0.0
        #secure-port: "0"
        #port: "10257"
    etcd:
      local:
        extraArgs:
          listen-metrics-urls: http://0.0.0.0:2381
    scheduler:
      extraArgs:
        bind-address: 0.0.0.0
        #secure-port: "0"
        #port: "10259"
  - |
    kind: KubeProxyConfiguration
    metricsBindAddress: 0.0.0.0
  extraMounts:
  - containerPath: /var/lib/kubelet/config.json
    hostPath: "$HOME/.docker/config.json"
  extraPortMappings:
    - containerPort: 443
      hostPort: 443
    - containerPort: 80
      hostPort: 80
EOF

kubectl wait --for condition=ready pod --namespace kube-system --all --timeout 300s

helm repo add argo https://argoproj.github.io/argo-helm
helm repo update
helm upgrade --install argocd -f argocd/values.yaml --wait -n argocd --create-namespace argo/argo-cd

echo ArgoCD initial password: $(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)

kubectl -n argocd port-forward service/argocd-server 8080:80 > /dev/null 2>&1 &

cat << EOF | kubectl -n argocd apply -f -
apiVersion: v1
data:
  config: eyJ0bHNDbGllbnRDb25maWciOnsiaW5zZWN1cmUiOmZhbHNlfX0=
  name: aW4tY2x1c3Rlcg==
  server: aHR0cHM6Ly9rdWJlcm5ldGVzLmRlZmF1bHQuc3Zj
kind: Secret
metadata:
  labels:
    argocd.argoproj.io/secret-type: cluster
    environment: management
  annotations:
    addons_repo_basepath: parameters-in-selector
    addons_repo_url: https://github.com/irizzante/argocd-experiments
    addons_repo_revision: HEAD
  name: in-cluster
  namespace: argocd
type: Opaque
EOF