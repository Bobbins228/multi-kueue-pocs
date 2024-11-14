# Multi Kueue on OpenShift
## Prerequisites 
* 2 Separate OpenShift Clusters (Manager Cluster, Worker Cluster)
* A Kube Config file authenticated to both Clusters

## NOTE:
* I have insecure-skip-tls-verify: true set in the shared config file (Not good but I will look into using certs)
* This is Kueue V0.9.0 (Multi Kueue enabled by default + KFTO supported)
* The installation of the MPI Operator was mandatory for MPI Jobs (Not ideal)
* Had to make alterations to the kube config file script so it worked on OpenShift
* NO RHOAI installed -> This is because v0.8.X of Kueue does not support KFTO Jobs


## Setup
* Gather the context for both OpenShift clusters. 
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
* OpenShift Version: v4.15.37
* Kueue Version: v0.9.0
* JobSet Version: v0.7.0
* KubeFlow Training Operator Version: v1.8.0 -> Worker Cluster
* KubeFlow Training Operator CRDs Version: v1.8.0 -> Manager Cluster
* MPI Operator Version: v0.6.0

Read [here](https://kueue.sigs.k8s.io/docs/tasks/manage/setup_multikueue/) for more information on Multi Kueue setup.
