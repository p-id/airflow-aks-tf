variable "client_id" { default = "sp-client-id" }

variable "client_secret" { default = "sp-creds-vault"}

variable "aad_sever_app_secret" { default = "aad server application hash"}

variable "tenant_id" {
  description = "default tenant id"
  default     = "WWWW-XXXX-YYYY-ZZZZ"
}

variable "resource_group_name" {
  default = "acp-va7-test-tf-rg_airflow"
}

variable "location" {
  default = "eastus2"
}

variable "linux_profile" {
  type = "map"

  default = {
    admin_username = "azureuser"
    ssh_public_key = "~/.ssh/azureuser_id_rsa.pub"
  }
}

variable "network_profile" {
  type = "map"

  default = {
    network_plugin     = "kubenet"
    docker_bridge_cidr = "10.43.192.1/18"
    dns_service_ip     = "10.43.128.10"
    vnet_cidr           = "10.43.0.0/17"
    subnet_cidr        = "10.43.0.0/17"
    service_cidr       = "10.43.128.0/18"
    load_balancer_sku  = "standard"
    service_endpoints  = "Microsoft.Sql"
  }
}

variable "os" {
  type = "map"

  default = {
    vm_size         = "Standard_F8s_v2"
    os_type         = "Linux"
    os_disk_size_gb = 30
    type            = "VirtualMachineScaleSets"
  }
}

variable "profile" {
  type = "map"

  default = {
    resource_group_vnet       = "acp-va7-nonprod-vnet-rg_airflow"
    vnet_name                 = "acp-va7-nonprod-vnet-airflow"
    vnet_cidr                 = "10.13.216.0/23"
    subnet_name               = "airflow-subnet-private-0"
    subnet_cidr               = "10.13.216.128/26"
    kubernetes_version        = "1.14.8"
    role_based_access_control = true
    nodes_count               = 3
    max_pods                  = 100
    dns_prefix                = "airflow"
    cluster_name              = "airflow-aks"
    http_application_routing  = false
    client_app_id             = "XXXX-YYYY-ZZZZ"
    server_app_id             = "WWWW-XXXX-YYYY-ZZZZ"
  }
}

variable "monitoring" {
  type = "map"

  default = {
    workspace_name                   = "airflow-log"
    workspace_sku                    = "PerNode"
    workspace_location               = "eastus"
    log_workspace_retention_in_days  = 30
    enable_oms_agent                 = true
  }
}

variable "org_tags" {
  type = "map"

  default = {
    ArchPath          = "Foundation.Platform.Airflow"
    CostCenter        = 99999
    Environment       = "Production"
    Owner             = "Airflow Cluster Mgr"
    Product           = "Airflow"
    PlatformComponent = "Airflow"
    environment       = "Stage"
    site              = "eastus"
  }
}
