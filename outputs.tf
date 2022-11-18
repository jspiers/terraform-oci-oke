output "cluster" {
  value = oci_containerengine_cluster.cluster
}

output "kubeconfig" {
  value = data.oci_containerengine_cluster_kube_config.kubeconfig.content
}
