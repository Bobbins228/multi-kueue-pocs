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

# Install Kueue v0.9.0
kubectl apply --server-side -f https://github.com/kubernetes-sigs/kueue/releases/download/v0.9.0/manifests.yaml
kubectl wait deploy/kueue-controller-manager -n kueue-system --for=condition=available --timeout=5m

# Install MPI Operator
kubectl apply --server-side -f https://raw.githubusercontent.com/kubeflow/mpi-operator/v0.6.0/deploy/v2beta1/mpi-operator.yaml
kubectl wait deploy/mpi-operator -n mpi-operator --for=condition=available --timeout=5m

# Ensure the context is set to worker
kubectl config use-context $WORKER_CONTEXT

# Install Kueue v0.9.0
kubectl apply --server-side -f https://github.com/kubernetes-sigs/kueue/releases/download/v0.9.0/manifests.yaml
kubectl wait deploy/kueue-controller-manager -n kueue-system --for=condition=available --timeout=5m

# Apply Kueue resources
kubectl apply --server-side -f kueue-resources/single-clusterqueue-setup.yaml

# Run the multikueue kubeconfig script
bash create-multikueue-kubeconfig.sh worker1.kubeconfig

# Install v0.7.0 of the JobSet Controller
kubectl apply --server-side -f https://github.com/kubernetes-sigs/jobset/releases/download/v0.7.0/manifests.yaml
kubectl wait deploy/jobset-controller-manager -n jobset-system --for=condition=available --timeout=5m

# Install MPI Operator
kubectl apply --server-side -f https://raw.githubusercontent.com/kubeflow/mpi-operator/v0.6.0/deploy/v2beta1/mpi-operator.yaml
kubectl wait deploy/mpi-operator -n mpi-operator --for=condition=available --timeout=5m

# Install the KFTO (v1.8.0)
kubectl apply -k "github.com/kubeflow/training-operator.git/manifests/overlays/standalone?ref=v1.8.0"
kubectl wait deploy/training-operator -n kubeflow --for=condition=available --timeout=5m

kubectl config use-context $MANAGER_CONTEXT

# Install just the KFTO CRDS on the Manager Cluster
kubectl apply --server-side -k "github.com/kubeflow/training-operator.git/manifests/base/crds?ref=v1.8.0"

# Install v0.7.0 of the JobSet Controller
kubectl apply --server-side -f https://github.com/kubernetes-sigs/jobset/releases/download/v0.7.0/manifests.yaml
kubectl wait deploy/jobset-controller-manager -n jobset-system --for=condition=available --timeout=5m

# Create the Worker kube config secret
kubectl create secret generic worker1-secret -n kueue-system --from-file=kubeconfig=worker1.kubeconfig

# Setup MultiKueue on Manager Cluster
kubectl apply -f kueue-resources/multikueue-setup.yaml

# Test MultiKueue is working correctly
kubectl get clusterqueues cluster-queue -o jsonpath="{range .status.conditions[?(@.type == \"Active\")]}CQ - Active: {@.status} Reason: {@.reason} Message: {@.message}{'\n'}{end}"
kubectl get admissionchecks sample-multikueue -o jsonpath="{range .status.conditions[?(@.type == \"Active\")]}AC - Active: {@.status} Reason: {@.reason} Message: {@.message}{'\n'}{end}"
kubectl get multikueuecluster multikueue-test-worker1 -o jsonpath="{range .status.conditions[?(@.type == \"Active\")]}MC - Active: {@.status} Reason: {@.reason} Message: {@.message}{'\n'}{end}"
