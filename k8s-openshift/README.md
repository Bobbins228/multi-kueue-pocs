# Multi Kueue on OpenShift and Kubernetes
## Prerequisites
* A Kubernetes Cluster(I used an EKS Cluster)
* An OpenShift Cluster
* A Kube Config file authenticated to both Clusters (Delete your old `~/.kube/config` file first!)

## NOTE:
* This PoC uses Kueue v0.10.0-rc.1 as it includes the integrations fix.
* This PoC has only been tested with a Manager OpenShift Cluster and a Worker Kubernetes Cluster different setups may vary your success rate.
* All integrations not essential to the PoC have been already disabled in the Kueue Manage ConfigMap included in the manifests.

## Setup
* Gather the context for both clusters. 
  e.g.
  ```
  kubectl config get-contexts

  CURRENT   NAME                             CLUSTER           AUTHINFO               NAMESPACE
  *         namespace/cluster_manager/user   cluster_manager   user/cluster_manager   namespace
            namespace/cluster_worker/user    cluster_worker    user/cluster_worker    namespace
  ```

* Run the setup_multi_kueue script to install all necessary operators/configurations
  ```
  # ./setup_multi_kueue.sh <MANAGER_CONTEXT> [WORKER_CONTEXT]
  ./setup_multi_kueue.sh namespace/cluster_manager/user namespace/cluster_worker/user
  ```

You can confirm that Multi Kueue is successfully set up if the script ends with:
```
CQ - Active: True Reason: Ready Message: Can admit new workloads
AC - Active: True Reason: Active Message: The admission check is active
MC - Active: True Reason: Active Message: Connected
``` 

## Test out Multi Kueue
* Set your context to the Manager Cluster 
  ```
  kubectl config use-context namespace/cluster_manager/user
  ```
* Apply the sample Pytorch Job
  ```
  kubectl apply -f pytorchjob-example.yaml
  ```
* The Worker Cluster should run the Pytorch job and upon completion the Pythorch Job CR should be deleted but remain on the Manager Cluster.

## Clean up
The `remove_kueue.sh` script will remove all resources created by the above example
```
./remove_kueue.sh namespace/cluster_manager/user namespace/cluster_worker/user
```
## Environment Details
Below is a list of installed Operators from this example and other useful environment information:
* Kueue Version: v0.10.0-rc.1
* KubeFlow Training Operator Version: v1.8.0 -> Worker Cluster
* KubeFlow Training Operator CRDs Version: v1.8.0 -> Manager Cluster

Read [here](https://kueue.sigs.k8s.io/docs/tasks/manage/setup_multikueue/) for more information on Multi Kueue setup.
