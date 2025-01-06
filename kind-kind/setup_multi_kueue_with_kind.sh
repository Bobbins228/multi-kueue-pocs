#!/bin/bash

MANAGER_CONTEXT=kind-manager
WORKER_CONTEXT=kind-worker

# Create Kind Clusters
kind create cluster --name=worker
kind create cluster --name=manager
# Create internal config file for worker cluster 
kind get kubeconfig --internal --name=worker > worker-config # Required for Kind Cluster to Kind Cluster communication

Ensure the context is set to manager
kubectl config use-context $MANAGER_CONTEXT

# Install Kueue v0.10.0
kubectl apply --server-side -f kueue-resources/manifests.yaml
kubectl wait deploy/kueue-controller-manager -n kueue-system --for=condition=available --timeout=5m



# Ensure the context is set to worker
kubectl config use-context $WORKER_CONTEXT

# Install Kueue v0.10.0
kubectl apply --server-side -f kueue-resources/manifests.yaml
kubectl wait deploy/kueue-controller-manager -n kueue-system --for=condition=available --timeout=5m

kubectl apply --server-side -f kueue-resources/single-clusterqueue-setup.yaml

bash create-multikueue-kubeconfig.sh worker1.kubeconfig

# Ensure the context is set to manager
kubectl config use-context $MANAGER_CONTEXT

kubectl create secret generic worker1-secret -n kueue-system --from-file=kubeconfig=worker1.kubeconfig

kubectl apply --server-side -f kueue-resources/multi-kueue-setup.yaml

# Check everything is setup correctly
kubectl get clusterqueues cluster-queue -o jsonpath="{range .status.conditions[?(@.type == \"Active\")]}CQ - Active: {@.status} Reason: {@.reason} Message: {@.message}{'\n'}{end}"
kubectl get admissionchecks sample-multikueue -o jsonpath="{range .status.conditions[?(@.type == \"Active\")]}AC - Active: {@.status} Reason: {@.reason} Message: {@.message}{'\n'}{end}"
kubectl get multikueuecluster multikueue-test-worker1 -o jsonpath="{range .status.conditions[?(@.type == \"Active\")]}MC - Active: {@.status} Reason: {@.reason} Message: {@.message}{'\n'}{end}"