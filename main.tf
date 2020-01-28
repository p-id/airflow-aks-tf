# create resource group for the azure kubernetes service (AKS)
resource "azurerm_resource_group" "airflow-aks" {
  name     = "${var.resource_group_name}"
  location = "${var.location}"

  tags = "${merge(var.org_tags, map("Org:Class", "ResourceGroup"))}"

  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_management_lock" "resource-group-level" {
  name = "${var.resource_group_name}-lock"
  scope = "${azurerm_resource_group.airflow-aks.id}"
  lock_level = "CanNotDelete"
  notes = "Locking the parent AKS Resource Group"
}

resource "azurerm_log_analytics_workspace" "airflow-aks-log-workspace" {
  name                = "${lookup(var.monitoring, "workspace_name")}"
  location            = "${lookup(var.monitoring, "workspace_location")}"
  resource_group_name = "${azurerm_resource_group.airflow-aks.name}" 
  sku                 = "${lookup(var.monitoring, "workspace_sku")}"
  retention_in_days   = "${lookup(var.monitoring, "log_workspace_retention_in_days")}"
}

resource "azurerm_log_analytics_solution" "airflow-aks-log-solution" {
    solution_name         = "ContainerInsights"
    location              = "${azurerm_log_analytics_workspace.airflow-aks-log-workspace.location}"
    resource_group_name   = "${azurerm_resource_group.airflow-aks.name}"
    workspace_resource_id = "${azurerm_log_analytics_workspace.airflow-aks-log-workspace.id}"
    workspace_name        = "${azurerm_log_analytics_workspace.airflow-aks-log-workspace.name}"

    plan {
        publisher = "Microsoft"
        product   = "OMSGallery/ContainerInsights"
    }
}

resource "azurerm_resource_group" "airflow-aks-vnet-rg" {
  name     = "${lookup(var.profile, "resource_group_vnet")}"
  location = "${var.location}"

  tags = "${merge(var.org_tags, map("Org:Class", "ResourceGroup"))}"

  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_virtual_network" "aks-vnet" {
  name                = "${lookup(var.profile, "vnet_name")}"
  location            = "${azurerm_resource_group.airflow-aks.location}" 
  resource_group_name = "${azurerm_resource_group.airflow-aks-vnet-rg.name}"
  address_space       = ["${lookup(var.profile, "subnet_cidr")}"]

  depends_on = ["azurerm_resource_group.airflow-aks-vnet-rg"]
}

resource "azurerm_subnet" "aks-subnet" {
  name                      = "${lookup(var.profile, "subnet_name")}"
  virtual_network_name      = "${azurerm_virtual_network.aks-vnet.name}"
  resource_group_name       = "${azurerm_virtual_network.aks-vnet.resource_group_name}"
  address_prefix            = "${lookup(var.profile, "subnet_cidr")}"
  service_endpoints         = ["${split(",", lookup(var.network_profile, "service_endpoints"))}"]

  depends_on = ["azurerm_virtual_network.aks-vnet"]
}

# create the AKS cluster
resource "azurerm_kubernetes_cluster" "airflow-aks" {
  name                = "${lookup(var.profile, "cluster_name")}"
  location            = "${azurerm_resource_group.airflow-aks.location}"
  resource_group_name = "${azurerm_resource_group.airflow-aks.name}"
  dns_prefix          = "${lookup(var.profile, "dns_prefix")}"

  linux_profile {
    admin_username = "${lookup(var.linux_profile, "admin_username")}"

    ssh_key {
      key_data = "${file("${lookup(var.linux_profile, "ssh_public_key")}")}"
    }
  }

  kubernetes_version = "${lookup(var.profile, "kubernetes_version")}"

  network_profile {
    network_plugin     = "${lookup(var.network_profile, "network_plugin")}"
    docker_bridge_cidr = "${lookup(var.network_profile, "docker_bridge_cidr")}"
    dns_service_ip     = "${lookup(var.network_profile, "dns_service_ip")}"
    pod_cidr           = "${lookup(var.network_profile, "pod_cidr")}"
    service_cidr       = "${lookup(var.network_profile, "service_cidr")}"
    load_balancer_sku  = "${lookup(var.network_profile, "load_balancer_sku")}"
  }

  agent_pool_profile {
    name            = "agentpool"
    count           = "${lookup(var.profile, "nodes_count")}"
    max_pods        = "${lookup(var.profile, "max_pods")}"
    vm_size         = "${lookup(var.os, "vm_size")}"
    os_type         = "${lookup(var.os, "os_type")}"
    os_disk_size_gb = "${lookup(var.os, "os_disk_size_gb")}"  # 0 will default to 30 GB
    type            = "${lookup(var.os, "type")}"

    # Required for advanced networking
    vnet_subnet_id  = "${azurerm_subnet.aks-subnet.id}"
  }

  service_principal {
    client_id     = "${var.client_id}"
    client_secret = "${var.client_secret}"
  }

  role_based_access_control {
    enabled = "${lookup(var.profile, "role_based_access_control")}"
    azure_active_directory {
      client_app_id     = "${lookup(var.profile, "client_app_id")}"
      server_app_id     = "${lookup(var.profile, "server_app_id")}"
      server_app_secret = "${var.aad_sever_app_secret}"
    }
  }

  addon_profile {
    http_application_routing {
      enabled = "${lookup(var.profile, "http_application_routing")}"
    }
    oms_agent {
      enabled = "${lookup(var.monitoring, "enable_oms_agent")}"
      log_analytics_workspace_id = "${azurerm_log_analytics_workspace.airflow-aks-log-workspace.id}"
    }
  }

  tags       = "${merge(var.org_tags, map("Org:Class", "AKS"), map("role", "aks"))}"
  depends_on = ["azurerm_resource_group.airflow-aks", "azurerm_subnet.aks-subnet"]

  lifecycle {
    prevent_destroy = true
  }
}
