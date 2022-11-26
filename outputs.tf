output "cluster" {
  value = oci_containerengine_cluster.cluster
}

output "kubeconfig" {
  value     = data.oci_containerengine_cluster_kube_config.kubeconfig.content
  sensitive = true
}

output "key" {
  value     = tls_private_key.public_private_key_pair[*]
  sensitive = true
}
