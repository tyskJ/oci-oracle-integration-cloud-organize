/************************************************************
Container Repository
************************************************************/
resource "oci_artifacts_container_repository" "this" {
  for_each = local.repos

  compartment_id = oci_identity_compartment.workload.id
  display_name   = "${each.value.prefix_name}/${each.value.fn_name}"
  is_immutable   = false
  is_public      = false
  # readme {}
}