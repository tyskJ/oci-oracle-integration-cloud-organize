/************************************************************
Auth Token
************************************************************/
resource "oci_identity_auth_token" "this" {
  user_id     = var.work_user_ocid
  description = "For OCI Container Registry Login PW"
}

resource "local_sensitive_file" "auth_token" {
  filename = "./.key/work_user_auth_token.txt"
  content  = oci_identity_auth_token.this.token
}

/************************************************************
Dynamic Group - Functions
************************************************************/
# 「oci_identity_dynamic_group」を使用する場合はルートコンパートメントのDefaultアイデンティティドメインにしか作成できない
# 「oci_identity_domains_dynamic_resource_group」を使用すれば、指定のアイデンティティドメインに作成可能
resource "oci_identity_dynamic_group" "functions" {
  compartment_id = var.tenancy_ocid
  name           = "Functions_Dynamic_Group"
  description    = "Functions Dynamic Group"
  matching_rule = format(
    "All {resource.type = 'fnfunc', resource.compartment.id = '%s'}",
    oci_identity_compartment.workload.id
  )
}

/************************************************************
IAM Policy - For Functions
************************************************************/
resource "oci_identity_policy" "functions_waf_policy" {
  compartment_id = var.tenancy_ocid
  description    = "OCI Functions Policy for Regional WAF Policy"
  name           = "functions-regional-waf-policy"
  statements = [
    format(
      "allow dynamic-group %s to use waf-policy in compartment %s",
      oci_identity_dynamic_group.functions.name,
      oci_identity_compartment.workload.name
    )
  ]
}

resource "oci_identity_policy" "functions_compute" {
  compartment_id = var.tenancy_ocid
  description    = "OCI Functions Policy for Compute Instance"
  name           = "functions-compute-instance-policy"
  statements = [
    format(
      "allow dynamic-group %s to read instances in compartment %s",
      oci_identity_dynamic_group.functions.name,
      oci_identity_compartment.workload.name
    ),
    format(
      "allow dynamic-group %s to {INSTANCE_POWER_ACTIONS} in compartment %s",
      oci_identity_dynamic_group.functions.name,
      oci_identity_compartment.workload.name
    )
  ]
}