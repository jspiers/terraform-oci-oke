variable "compartment_id" {
  type = string
}

variable "vcn_name" {
  type    = string
  default = "vcn"
}

variable "vcn_cidr" {
  type    = string
  default = "10.1.0.0/16"
}

variable "cluster_name" {
  type    = string
  default = "oke"
}

variable "kubernetes_version" {
  type    = string
  default = "v1.26.2"
}

variable "node_pools" {
  type = map(object({
    shape                    = string
    ocpus                    = number
    memory                   = number
    size                     = number
    operating_system         = string
    operating_system_version = string
    initial_node_labels      = map(string)
    boot_volume_size_in_gbs  = number
  }))
  default = {
    trident = {
      shape                    = "VM.Standard.A1.Flex"
      ocpus                    = 1
      memory                   = 6
      size                     = 3
      operating_system         = "Oracle Linux"
      operating_system_version = "8"
      initial_node_labels = {
        key = "value"
      }
      boot_volume_size_in_gbs = null # use default
    }
  }
}

variable "is_api_subnet_public" {
  type    = bool
  default = true
}

variable "is_loadbalancer_subnet_public" {
  type    = bool
  default = true
}

variable "is_nodes_subnet_public" {
  type    = bool
  default = false
}

variable "is_pv_encryption_in_transit_enabled" {
  type    = bool
  default = false
}

variable "pods_cidr" {
  type    = string
  default = "10.200.0.0/16"
}

variable "services_cidr" {
  type    = string
  default = "10.201.0.0/16"
}

variable "is_kubernetes_dashboard_enabled" {
  type    = bool
  default = false
}

variable "is_tiller_enabled" {
  type    = bool
  default = false
}

variable "is_pod_security_policy_enabled" {
  type    = bool
  default = false
}

variable "cluster_kube_config_token_version" {
  type    = string
  default = "2.0.0"
}

variable "ssh_public_key" {
  type    = string
  default = ""
}

variable "defined_tags" {
  type    = map(string)
  default = null
}
