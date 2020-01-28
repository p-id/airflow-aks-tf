output "client_key" {
    value = "${azurerm_kubernetes_cluster.airflow-aks.kube_config.0.client_key}"
}

output "client_certificate" {
    value = "${azurerm_kubernetes_cluster.airflow-aks.kube_config.0.client_certificate}"
}

output "cluster_ca_certificate" {
    value = "${azurerm_kubernetes_cluster.airflow-aks.kube_config.0.cluster_ca_certificate}"
}

output "cluster_username" {
    value = "${azurerm_kubernetes_cluster.airflow-aks.kube_config.0.username}"
}

output "cluster_password" {
    value = "${azurerm_kubernetes_cluster.airflow-aks.kube_config.0.password}"
}

output "kube_config" {
    value = "${azurerm_kubernetes_cluster.airflow-aks.kube_config_raw}"
}

output "host" {
    value = "${azurerm_kubernetes_cluster.airflow-aks.kube_config.0.host}"
}

output "log_analytics_url" {
    value = "${azurerm_log_analytics_workspace.airflow-aks-log-workspace.portal_url}"
}

output "primary_shared_key" {
    value = "${azurerm_log_analytics_workspace.airflow-aks-log-workspace.primary_shared_key}"
}

output "secondary_shared_key" {
    value = "${azurerm_log_analytics_workspace.airflow-aks-log-workspace.secondary_shared_key}"
}
