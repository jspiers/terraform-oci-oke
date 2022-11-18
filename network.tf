## Copyright © 2021, Oracle and/or its affiliates. 
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

resource "oci_core_vcn" "vcn" {
  count          = var.use_existing_vcn ? 0 : 1
  cidr_block     = var.vcn_cidr
  compartment_id = var.compartment_id
  display_name   = "vcn"
  defined_tags   = var.defined_tags
}

resource "oci_core_service_gateway" "sgw" {
  count          = var.use_existing_vcn ? 0 : 1
  compartment_id = var.compartment_id
  display_name   = "sgw"
  vcn_id         = oci_core_vcn.vcn[0].id
  services {
    service_id = lookup(data.oci_core_services.all[0].services[0], "id")
  }
  defined_tags = var.defined_tags
}

resource "oci_core_nat_gateway" "natgw" {
  count          = var.use_existing_vcn ? 0 : 1
  compartment_id = var.compartment_id
  display_name   = "natgw"
  vcn_id         = oci_core_vcn.vcn[0].id
  defined_tags   = var.defined_tags
}

resource "oci_core_route_table" "natgw_and_sgw" {
  count          = var.use_existing_vcn ? 0 : 1
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.vcn[0].id
  display_name   = "natgw"
  defined_tags   = var.defined_tags

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_nat_gateway.natgw[0].id
  }

  route_rules {
    destination       = lookup(data.oci_core_services.all[0].services[0], "cidr_block")
    destination_type  = "SERVICE_CIDR_BLOCK"
    network_entity_id = oci_core_service_gateway.sgw[0].id
  }
}

resource "oci_core_internet_gateway" "igw" {
  count          = var.use_existing_vcn ? 0 : 1
  compartment_id = var.compartment_id
  display_name   = "igw"
  vcn_id         = oci_core_vcn.vcn[0].id
  defined_tags   = var.defined_tags
}

resource "oci_core_route_table" "igw" {
  count          = var.use_existing_vcn ? 0 : 1
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.vcn[0].id
  display_name   = "igw"
  defined_tags   = var.defined_tags

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.igw[0].id
  }
}

resource "oci_core_security_list" "api_subnet_sec_list" {
  count          = var.use_existing_vcn ? 0 : 1
  compartment_id = var.compartment_id
  display_name   = "api_subnet_sec_list"
  vcn_id         = oci_core_vcn.vcn[0].id
  defined_tags   = var.defined_tags

  # egress_security_rules

  egress_security_rules {
    protocol         = "6"
    destination_type = "CIDR_BLOCK"
    destination      = var.nodes_subnet_cidr
  }

  egress_security_rules {
    protocol         = 1
    destination_type = "CIDR_BLOCK"
    destination      = var.nodes_subnet_cidr

    icmp_options {
      type = 3
      code = 4
    }
  }

  egress_security_rules {
    protocol         = "6"
    destination_type = "SERVICE_CIDR_BLOCK"
    destination      = lookup(data.oci_core_services.all[0].services[0], "cidr_block")

    tcp_options {
      min = 443
      max = 443
    }
  }

  ingress_security_rules {
    protocol = "6"
    source   = var.nodes_subnet_cidr

    tcp_options {
      min = 6443
      max = 6443
    }
  }

  ingress_security_rules {
    protocol = "6"
    source   = var.nodes_subnet_cidr

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
    source   = var.nodes_subnet_cidr

    icmp_options {
      type = 3
      code = 4
    }
  }

}

resource "oci_core_security_list" "nodes_subnet_sec_list" {
  count          = var.use_existing_vcn ? 0 : 1
  compartment_id = var.compartment_id
  display_name   = "nodes_subnet_sec_list"
  vcn_id         = oci_core_vcn.vcn[0].id
  defined_tags   = var.defined_tags

  egress_security_rules {
    protocol         = "All"
    destination_type = "CIDR_BLOCK"
    destination      = var.nodes_subnet_cidr
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
    destination      = lookup(data.oci_core_services.all[0].services[0], "cidr_block")
  }

  egress_security_rules {
    protocol         = "6"
    destination_type = "CIDR_BLOCK"
    destination      = var.api_subnet_cidr

    tcp_options {
      min = 6443
      max = 6443
    }
  }

  egress_security_rules {
    protocol         = "6"
    destination_type = "CIDR_BLOCK"
    destination      = var.api_subnet_cidr

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
    source   = var.nodes_subnet_cidr
  }

  ingress_security_rules {
    protocol = "6"
    source   = var.api_subnet_cidr
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

resource "oci_core_subnet" "api_subnet" {
  count                      = (var.use_existing_vcn && var.vcn_native) ? 0 : 1
  cidr_block                 = var.api_subnet_cidr
  compartment_id             = var.compartment_id
  vcn_id                     = oci_core_vcn.vcn[0].id
  display_name               = "api_subnet"
  security_list_ids          = [oci_core_vcn.vcn[0].default_security_list_id, oci_core_security_list.api_subnet_sec_list[0].id]
  route_table_id             = var.is_api_subnet_public ? oci_core_route_table.igw[0].id : oci_core_route_table.natgw_and_sgw[0].id
  prohibit_public_ip_on_vnic = var.is_api_subnet_public ? false : true
  defined_tags               = var.defined_tags
}

resource "oci_core_subnet" "loadbalancer_subnet" {
  count          = (var.use_existing_vcn && var.vcn_native) ? 0 : 1
  cidr_block     = var.loadbalancer_subnet_cidr
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.vcn[0].id
  display_name   = "loadbalancer_subnet"

  security_list_ids          = [oci_core_vcn.vcn[0].default_security_list_id]
  route_table_id             = var.is_loadbalancer_subnet_public ? oci_core_route_table.igw[0].id : oci_core_route_table.natgw_and_sgw[0].id
  prohibit_public_ip_on_vnic = var.is_loadbalancer_subnet_public ? false : true
  defined_tags               = var.defined_tags
}

resource "oci_core_subnet" "nodes_subnet" {
  count          = (var.use_existing_vcn && var.vcn_native) ? 0 : 1
  cidr_block     = var.nodes_subnet_cidr
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.vcn[0].id
  display_name   = "nodes_subnet"

  security_list_ids          = [oci_core_vcn.vcn[0].default_security_list_id, oci_core_security_list.nodes_subnet_sec_list[0].id]
  route_table_id             = var.is_nodes_subnet_public ? oci_core_route_table.igw[0].id : oci_core_route_table.natgw_and_sgw[0].id
  prohibit_public_ip_on_vnic = var.is_nodes_subnet_public ? false : true
  defined_tags               = var.defined_tags
}



