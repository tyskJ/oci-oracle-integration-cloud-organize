/************************************************************
OIC インスタンス
************************************************************/
resource "oci_integration_integration_instance" "developer" {
  compartment_id            = oci_identity_compartment.workload.id
  display_name              = "integration-instance"
  state                     = "ACTIVE"
  domain_id                 = var.default_domain_id
  integration_instance_type = "STANDARDX"
  shape                     = "DEVELOPMENT"
  is_byol                   = false
  message_packs             = 1
  network_endpoint_details {
    # loopback enable
    is_integration_vcn_allowlisted = true
    # HTTP (Console)
    network_endpoint_type = "PUBLIC"
    allowlisted_http_ips = [
      var.source_ip
    ]
  }
  lifecycle {
    ignore_changes = [
      system_tags
    ]
  }
}