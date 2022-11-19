data "oci_core_images" "node" {
  for_each                 = var.node_pools
  compartment_id           = var.compartment_id
  operating_system         = each.value.operating_system
  operating_system_version = each.value.operating_system_version
  shape                    = each.value.shape
  state                    = "AVAILABLE"
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

data "oci_core_services" "all" {
  # count = var.use_existing_vcn ? 0 : 1
  filter {
    name   = "name"
    values = ["All .* Services In Oracle Services Network"]
    regex  = true
  }
}

data "oci_identity_availability_domains" "ADs" {
  compartment_id = var.compartment_id
}

data "oci_containerengine_cluster_kube_config" "kubeconfig" {
  cluster_id    = oci_containerengine_cluster.cluster.id
  token_version = var.cluster_kube_config_token_version
}
