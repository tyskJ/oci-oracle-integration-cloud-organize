/************************************************************
Compartment - workload
************************************************************/
resource "oci_identity_compartment" "workload" {
  compartment_id = var.tenancy_ocid
  name           = "oci-oracle-integration-cloud-organize"
  description    = "For OCI Oracle Integration Cloud Organize"
  enable_delete  = true
}