resource "oci_core_vcn" "vcn" {
  cidr_block     = var.vcn_cidr
  compartment_id = var.compartment_id
  display_name   = "vcn"
}

locals {
  subnet_cidrs = {
    nodes        = cidrsubnet(var.vcn_cidr, 8, 1)
    loadbalancer = cidrsubnet(var.vcn_cidr, 8, 2)
    api          = cidrsubnet(var.vcn_cidr, 8, 3)
  }
}

resource "oci_core_service_gateway" "sgw" {
  compartment_id = var.compartment_id
  display_name   = "sgw"
  vcn_id         = oci_core_vcn.vcn.id
  services {
    service_id = lookup(data.oci_core_services.all.services[0], "id")
  }
}

resource "oci_core_nat_gateway" "natgw" {
  compartment_id = var.compartment_id
  display_name   = "natgw"
  vcn_id         = oci_core_vcn.vcn.id
}

resource "oci_core_route_table" "natgw_and_sgw" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.vcn.id
  display_name   = "natgw"
  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_nat_gateway.natgw.id
  }
  route_rules {
    destination       = lookup(data.oci_core_services.all.services[0], "cidr_block")
    destination_type  = "SERVICE_CIDR_BLOCK"
    network_entity_id = oci_core_service_gateway.sgw.id
  }
}

resource "oci_core_internet_gateway" "igw" {
  compartment_id = var.compartment_id
  display_name   = "igw"
  vcn_id         = oci_core_vcn.vcn.id
}

resource "oci_core_route_table" "igw" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.vcn.id
  display_name   = "igw"
  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.igw.id
  }
}

resource "oci_core_security_list" "api_sec_list" {
  compartment_id = var.compartment_id
  display_name   = "api_sec_list"
  vcn_id         = oci_core_vcn.vcn.id
  egress_security_rules {
    protocol         = "6"
    destination_type = "CIDR_BLOCK"
    destination      = local.subnet_cidrs["nodes"]
  }
  egress_security_rules {
    protocol         = 1
    destination_type = "CIDR_BLOCK"
    destination      = local.subnet_cidrs["nodes"]
    icmp_options {
      type = 3
      code = 4
    }
  }
  egress_security_rules {
    protocol         = "6"
    destination_type = "SERVICE_CIDR_BLOCK"
    destination      = lookup(data.oci_core_services.all.services[0], "cidr_block")
    tcp_options {
      min = 443
      max = 443
    }
  }
  ingress_security_rules {
    protocol = "6"
    source   = local.subnet_cidrs["nodes"]
    tcp_options {
      min = 6443
      max = 6443
    }
  }
  ingress_security_rules {
    protocol = "6"
    source   = local.subnet_cidrs["nodes"]
    tcp_options {
      min = 12250
      max = 12250
    }
  }
  ingress_security_rules {
    protocol = "6"
    source   = "0.0.0.0/0"
    tcp_options {
      min = 6443
      max = 6443
    }
  }
  ingress_security_rules {
    protocol = 1
    source   = local.subnet_cidrs["nodes"]
    icmp_options {
      type = 3
      code = 4
    }
  }
}

resource "oci_core_security_list" "nodes_sec_list" {
  compartment_id = var.compartment_id
  display_name   = "nodes_sec_list"
  vcn_id         = oci_core_vcn.vcn.id
  egress_security_rules {
    protocol         = "All"
    destination_type = "CIDR_BLOCK"
    destination      = local.subnet_cidrs["nodes"]
  }
  egress_security_rules {
    protocol    = 1
    destination = "0.0.0.0/0"
    icmp_options {
      type = 3
      code = 4
    }
  }
  egress_security_rules {
    protocol         = "6"
    destination_type = "SERVICE_CIDR_BLOCK"
    destination      = lookup(data.oci_core_services.all.services[0], "cidr_block")
  }
  egress_security_rules {
    protocol         = "6"
    destination_type = "CIDR_BLOCK"
    destination      = local.subnet_cidrs["api"]
    tcp_options {
      min = 6443
      max = 6443
    }
  }
  egress_security_rules {
    protocol         = "6"
    destination_type = "CIDR_BLOCK"
    destination      = local.subnet_cidrs["api"]
    tcp_options {
      min = 12250
      max = 12250
    }
  }
  egress_security_rules {
    protocol         = "6"
    destination_type = "CIDR_BLOCK"
    destination      = "0.0.0.0/0"
  }
  ingress_security_rules {
    protocol = "All"
    source   = local.subnet_cidrs["nodes"]
  }
  ingress_security_rules {
    protocol = "6"
    source   = local.subnet_cidrs["api"]
  }
  ingress_security_rules {
    protocol = 1
    source   = "0.0.0.0/0"
    icmp_options {
      type = 3
      code = 4
    }
  }
  ingress_security_rules {
    protocol = "6"
    source   = "0.0.0.0/0"
    tcp_options {
      min = 22
      max = 22
    }
  }
}

resource "oci_core_subnet" "api" {
  cidr_block     = local.subnet_cidrs["api"]
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.vcn.id
  display_name   = "api"
  security_list_ids = [
    oci_core_vcn.vcn.default_security_list_id,
    oci_core_security_list.api_sec_list.id
  ]
  route_table_id             = var.is_api_subnet_public ? oci_core_route_table.igw.id : oci_core_route_table.natgw_and_sgw.id
  prohibit_public_ip_on_vnic = var.is_api_subnet_public ? false : true
}

resource "oci_core_subnet" "loadbalancer" {
  cidr_block                 = local.subnet_cidrs["loadbalancer"]
  compartment_id             = var.compartment_id
  vcn_id                     = oci_core_vcn.vcn.id
  display_name               = "loadbalancer"
  security_list_ids          = [oci_core_vcn.vcn.default_security_list_id]
  route_table_id             = var.is_loadbalancer_subnet_public ? oci_core_route_table.igw.id : oci_core_route_table.natgw_and_sgw.id
  prohibit_public_ip_on_vnic = var.is_loadbalancer_subnet_public ? false : true
}

resource "oci_core_subnet" "nodes" {
  cidr_block     = local.subnet_cidrs["nodes"]
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.vcn.id
  display_name   = "nodes"
  security_list_ids = [
    oci_core_vcn.vcn.default_security_list_id,
    oci_core_security_list.nodes_sec_list.id
  ]
  route_table_id             = var.is_nodes_subnet_public ? oci_core_route_table.igw.id : oci_core_route_table.natgw_and_sgw.id
  prohibit_public_ip_on_vnic = var.is_nodes_subnet_public ? false : true
}
