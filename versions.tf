terraform {
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "~> 4.100"
    }
    tls = "~> 4.0"
  }
}
