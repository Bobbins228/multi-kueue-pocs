#!/bin/bash

if [ $# -eq 2 ]; then
    MANAGER_CONTEXT=$1
    WORKER_CONTEXT=$2
    echo "MANAGER_CONTEXT is set to $MANAGER_CONTEXT"
    echo "WORKER_CONTEXT is set to $WORKER_CONTEXT"
elif [ $# -eq 1 ]; then
    MANAGER_CONTEXT=$1
    echo "MANAGER_CONTEXT is set to $MANAGER_CONTEXT"
    echo "No WORKER_CONTEXT provided"
    exit 1
elif [ $# -eq 0 ]; then
    echo "No MANAGER_CONTEXT or WORKER_CONTEXT provided"
    exit 1
else
    echo "Invalid number of arguments. Usage: ./setup_multi_kueue.sh <MANAGER_CONTEXT> [WORKER_CONTEXT]"
    exit 1
fi

# Ensure the context is set to manager
kubectl config use-context $MANAGER_CONTEXT

# Install Kueue v0.10.0-rc.1
# NOTE: I removed all of the integrations that are not KubeFlow(bar MPI) and batch
kubectl apply --server-side -f kueue-resources/manifests.yaml
kubectl wait deploy/kueue-controller-manager -n kueue-system --for=condition=available --timeout=5m

# Ensure the context is set to worker
kubectl config use-context $WORKER_CONTEXT

# Install Kueue v0.10.0-rc.1
# NOTE: I removed all of the integrations that are not KubeFlow(bar MPI) and batch
kubectl apply --server-side -f kueue-resources/manifests.yaml
kubectl wait deploy/kueue-controller-manager -n kueue-system --for=condition=available --timeout=5m

# Apply Kueue Resources
kubectl apply --server-side -f kueue-resources/single-clusterqueue-setup.yaml

# Run the multikueue kubeconfig script
bash create-multikueue-kubeconfig.sh worker1.kubeconfig

# Install the Training Operator v1.8.0
kubectl apply -k "github.com/kubeflow/training-operator.git/manifests/overlays/standalone?ref=v1.8.0"
kubectl wait deploy/training-operator -n kubeflow --for=condition=available --timeout=5m

# Ensure the context is set to Manager
kubectl config use-context $MANAGER_CONTEXT

# Install just the Training Operator CRDs
kubectl apply --server-side -k "github.com/kubeflow/training-operator.git/manifests/base/crds?ref=v1.8.0"

# Create the Worker kube config secret
kubectl create secret generic worker1-secret -n kueue-system --from-file=kubeconfig=worker1.kubeconfig

# Setup MultiKueue on Manager Cluster
kubectl apply -f kueue-resources/multikueue-setup.yaml

# Test MultiKueue is working correctly
kubectl get clusterqueues cluster-queue -o jsonpath="{range .status.conditions[?(@.type == \"Active\")]}CQ - Active: {@.status} Reason: {@.reason} Message: {@.message}{'\n'}{end}"
kubectl get admissionchecks sample-multikueue -o jsonpath="{range .status.conditions[?(@.type == \"Active\")]}AC - Active: {@.status} Reason: {@.reason} Message: {@.message}{'\n'}{end}"
kubectl get multikueuecluster multikueue-test-worker1 -o jsonpath="{range .status.conditions[?(@.type == \"Active\")]}MC - Active: {@.status} Reason: {@.reason} Message: {@.message}{'\n'}{end}"

# The above commands should print out the following
# CQ - Active: True Reason: Ready Message: Can admit new workloads
# AC - Active: True Reason: Active Message: The admission check is active
# MC - Active: True Reason: Active Message: Connected

