#! /bin/bash

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
    echo "Invalid number of arguments. Usage: ./remove_kueue.sh <MANAGER_CONTEXT> [WORKER_CONTEXT]"
    exit 1
fi

MULTIKUEUE_SA=multikueue-sa
NAMESPACE=kueue-system

kubectl config use-context $MANAGER_CONTEXT

kubectl delete -f kueue-resources/multikueue-setup.yaml
kubectl delete secret worker1-secret -n kueue-system

kubectl config use-context $WORKER_CONTEXT
kubectl delete secret $MULTIKUEUE_SA -n $NAMESPACE
kubectl delete ClusterRoleBinding $MULTIKUEUE_SA-crb
kubectl delete ClusterRole $MULTIKUEUE_SA-role
kubectl delete ServiceAccount $MULTIKUEUE_SA

kubectl delete -f https://raw.githubusercontent.com/kubeflow/mpi-operator/v0.6.0/deploy/v2beta1/mpi-operator.yaml
kubectl delete -k "github.com/kubeflow/training-operator.git/manifests/overlays/standalone?ref=v1.8.0"
kubectl delete -f kueue-resources/single-clusterqueue-setup.yaml

kubectl delete -f https://github.com/kubernetes-sigs/kueue/releases/download/v0.9.0/manifests.yaml

kubectl config use-context $MANAGER_CONTEXT

kubectl delete -f https://raw.githubusercontent.com/kubeflow/mpi-operator/v0.6.0/deploy/v2beta1/mpi-operator.yaml
kubectl delete -k "github.com/kubeflow/training-operator.git/manifests/base/crds?ref=v1.8.0"
kubectl delete -f https://github.com/kubernetes-sigs/kueue/releases/download/v0.9.0/manifests.yaml
