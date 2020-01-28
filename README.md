# Overview
Terraform module for creating an AKS cluster for Airflow deployment

# Prerequisites
* Install Terraform distributed as a Golang-based single binary to be included in execution path similar to $HOME/bin
* Additional tools for Azure/Kubernetes - az cli, Kubectl and helm
* An existing SP, secret in a keyvault that can be accessed from arm deployment - [for pre-production/production cluster done via Octo]

```
:NOTE: Work-in-progress - additional best practice to adopt for a long running cluster
  * Save/backup the Terraform deployment state in an Azure storage account as a Blob
  * Secrets for a service-principal to be stored in Azure vault for credential rotation and access-auditing
```

```sh
$ az login
$ az account show --query "{subscriptionId:id, tenantId:tenantId}"
$ az ad sp create-for-rbac --role="Contributor" --scopes="/subscriptions/<Your Subscription ID>/resourcegroups/acp-airflow-ex" --name="http://airflow-dev-sp-ex"
```
The data cand be saved in a separate .tfvars file to not be asked for it everytime.

```
NOTE Requires a service principal to be created before.
Also, extend the service principal duration to 1 year (Only till Azure provides capbility to rotate service-principal for an existing cluster)
az ad sp credential reset --name <aadClientId> --password <aadClientSecret> --years 1
```

example: secrets.tfvars
```
client_id = "<Your Service Provider ID>"
client_secret = "<Your Service Provider Password>"
aad_sever_app_secret = "<Your AAD application directory secret>"
```

```sh
$ terraform init
$ terraform plan -var-file="secrets.tfvars"
$ terraform apply -var-file="secrets.tfvars"
```

Also need a ssh key for azureuser. Use the name for the file "azureuser_id_rsa".
```sh
$ ssh-keygen -t rsa -b 2048 -C "azureuser"
```

# Updating exposed variables as required

## Basic AKS provisioning
Variable | Default | Description 
--------|----------|------------
resource_group_name | eastus-dataservice-rg_airflow_aks | Resource group for AKS cluster
location | eastus2 | AKS Cluster region to deploy on
linux_profile.admin_username | azureuser | Linux admin user-name

## AKS network model and related options
Variable | Default | Description 
--------|----------|------------
network_profile.network_plugin | azure | CNI plugin to use for AKS deployment - defaults to advanced networking - another option kubenet
network_profile.docker_bridge_cidr | "10.91.55.1/25" | CIDR block to use for docker-bridge
network_profile.service_cidr | "10.81.55.128/25" | CIDR block to use for K8S services
network_profile.pod_cidr | "10.61.72.0/21" | CIDR block to use for K8S inter-pod/node connectivity
network_profile.dns_service_ip | "10.81.55.135" | Reserved IP from service CIDR block

## AKS Node provisioning
Variable | Default | Description 
--------|----------|------------
vm_size| Standard_F8s_v2 | Compute SKU to use - [prefer Standard_D8s_v3] as per recommendation from Azure
os_disk_size_gb | 30 | Default to 30 GB - use value as 0 to default to SKU's default size

## AKS - K8S specific parameters
Variable | Default | Description 
--------|----------|------------
kubernetes_version | 1.11.5 | Kubernetes version to use
role_based_access_control | true | K8S Role-based access control
nodes_count | 3 | Number of compute nodes to provision
max_pods | 110 | Number of maximum pods per nodes [Azure default to 30 pods per node]
dns_prefix | scheduler | DNS prefix to use for k8s cluster
cluster_name | eastus-data-service-airflow-aks | Cluster name as visible in Azure portal
http_application_routing | true | HTTP application level routing

## AKS - Log Analytics and monitoring
Variable | Default | Description 
--------|----------|------------
workspace_name | eastus-data-service-airflow-scheduler-log | Log analytics workspace name
workspace_sku | PerGB2018 | Workspace SKU to use
log_workspace_retention_in_days | 180 | Default log retention set to 180 days
enable_oms_agent | true | enable azure container monitoring

Additional variables related to resource tagging are present - mostly self-descriptive and to be updated mostly once per project basis

# Terraform output variable
Variable | Description 
--------|------------
host | AKS cluster Kube-API access-point FQDN
kube_config | Kube-config yaml file to access K8S cluster remotely
log_analytics_url | Log analytics portal url
primary_shared_key | Log analytics primary shared key 

## Use kubectl proxy to browse AKS cluster

Extract and setup kube-config for deployed cluster

```sh
$ echo "$(terraform output kube_config)" > ~/.kube/azurek8s-airflow
$ export KUBECONFIG=~/.kube/azurek8s-airflow
```

Start up kubectl proxy to browse dashboard

```sh
$ kubectl proxy
$ open 'http://localhost:8001/api/v1/namespaces/kube-system/services/kubernetes-dashboard/proxy/#!/overview?namespace=default'
```

## Use Log Analytics
Get portal url/workspace-id from terraform output - Active directory access needs to be provisioned for desired dev-group as required
```sh
$ terraform output log_analytics_url
```

# Kubernetes manifest file
 * Splunk enterprise connect for K8S
 Deployed via Helm chart as

```sh
$ helm install --name aks-splunk-logging -f aks_splunk_logging.yaml https://github.com/splunk/splunk-connect-for-kubernetes/releases/download/v1.0.1/splunk-kubernetes-logging-1.0.1.tgz
```

Example value file under k8s-manifests folder

# Kubernetes dashboard RBAC control
```sh
:TODO: - work-in-progress
Currently, enabling federated authentication for dashboard has a caveat that execution of each kubectl would also require fetching a token for a specific duration - this does have an impact of various provisioning scripts
```
