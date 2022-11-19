resource "tls_private_key" "public_private_key_pair" {
  algorithm = "RSA"
  rsa_bits  = 4096
  count     = var.ssh_public_key == "" ? 1 : 0
}

resource "oci_containerengine_cluster" "cluster" {
  compartment_id     = var.compartment_id
  kubernetes_version = var.kubernetes_version
  name               = var.cluster_name
  # vcn_id             = var.use_existing_vcn ? var.vcn_id : oci_core_vcn.vcn[0].id
  vcn_id = oci_core_vcn.vcn.id

  dynamic "endpoint_config" {
    for_each = var.vcn_native ? [1] : []
    content {
      is_public_ip_enabled = var.is_api_subnet_public
      subnet_id            = oci_core_subnet.api.id
    }
  }

  options {
    service_lb_subnet_ids = [oci_core_subnet.loadbalancer.id]

    add_ons {
      is_kubernetes_dashboard_enabled = var.is_kubernetes_dashboard_enabled
      is_tiller_enabled               = var.is_tiller_enabled
    }

    admission_controller_options {
      is_pod_security_policy_enabled = var.is_pod_security_policy_enabled
    }

    kubernetes_network_config {
      pods_cidr     = var.pods_cidr
      services_cidr = var.services_cidr
    }
  }
  defined_tags = var.defined_tags
}

resource "oci_containerengine_node_pool" "pools" {
  for_each           = var.node_pools
  cluster_id         = oci_containerengine_cluster.cluster.id
  compartment_id     = var.compartment_id
  kubernetes_version = var.kubernetes_version
  name               = each.key
  node_shape         = each.value.shape
  node_shape_config {
    ocpus         = each.value.ocpus
    memory_in_gbs = each.value.memory
  }
  initial_node_labels {
    key   = var.node_pool_initial_node_labels_key
    value = var.node_pool_initial_node_labels_value
  }
  node_source_details {
    # Use latest compatible image if none is explicitly specified
    image_id    = data.oci_core_images.node[each.key].images[0].id
    source_type = "IMAGE"
    # boot_volume_size_in_gbs = each.value.boot_volume_size_in_gbs
  }
  ssh_public_key = var.ssh_public_key != "" ? var.ssh_public_key : tls_private_key.public_private_key_pair[0].public_key_openssh
  node_config_details {
    placement_configs {
      availability_domain = data.oci_identity_availability_domains.ADs.availability_domains[0]["name"]
      subnet_id           = oci_core_subnet.nodes.id
    }
    is_pv_encryption_in_transit_enabled = var.is_pv_encryption_in_transit_enabled
    size                                = each.value.size
    defined_tags                        = var.defined_tags
  }
  node_eviction_node_pool_settings {
    eviction_grace_duration = "PT60M" # 1 hour
  }
  defined_tags = var.defined_tags
}
