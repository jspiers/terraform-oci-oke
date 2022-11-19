# Terraform a Kubernetes cluster on Oracle Cloud Infrastructure (OCI)

Inspired by [oci-oke](https://github.com/oracle-quickstart/oci-oke) Oracle quickstart guide.

## Design choices
Both the Kubernetes API endpoint and the service load balancer are public.
Corresponds to the use-case defined [here](https://docs.oracle.com/en-us/iaas/Content/ContEng/Concepts/contengnetworkconfigexample.htm#example-publick8sapi-privateworkers-publiclb).

<img align="center" src="https://docs.oracle.com/en-us/iaas/Content/Resources/Images/conteng-network-eg2.png">

