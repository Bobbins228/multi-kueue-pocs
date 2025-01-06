# MultiKueue with 2 Kind Clusters
## Prerequisites 
* [Kind](https://kind.sigs.k8s.io/) installed on your machine.
* [kubectl](https://kubernetes.io/docs/reference/kubectl/)

## NOTE:
* This is Kueue V0.10.0
* This MultiKueue example is setup for only testing Batch Jobs NOT via the `managedBy` method 

## Setup
* Run `./setup_multi_kueue_with_kind.sh`
* 2 Kind Clusters named `manager` and `worker` will be created and configured for MultiKueue.

## Testing
* Apply the `job.yaml` Batch Job to the Manager Cluster (switch context with `kubectl config use-context kind-manager`)
* Check that both Clusters have a Job Workload and that the Job Pods are only running on the Worker Cluster.

## Cleanup
* Run `./cleanup.sh` to delete both Kind Clusters
