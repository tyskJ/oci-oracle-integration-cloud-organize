/************************************************************
Application
************************************************************/
resource "oci_functions_application" "this" {
  for_each = local.apps

  compartment_id = oci_identity_compartment.workload.id
  display_name   = each.value.name
  subnet_ids = [
    oci_core_subnet.private_functions.id
  ]
  shape               = "GENERIC_X86"
  security_attributes = {}
  config              = {}
  network_security_group_ids = [
    oci_core_network_security_group.sg_functions_app.id
  ]
  syslog_url = null
  trace_config {
    is_enabled = false
  }
  image_policy_config {
    is_policy_enabled = false
  }
}

resource "terraform_data" "fn_delete" {
  for_each = local.apps

  depends_on = [
    oci_functions_application.this
  ]
  input = {
    fn_ocid : each.value.fn_ocid
  }
  provisioner "local-exec" {
    when    = destroy
    command = <<EOT
    oci fn function delete \
    --function-id ${self.input.fn_ocid} \
    --force \
    --profile ADMIN \
    --auth security_token
    EOT
  }
}