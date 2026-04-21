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

/************************************************************
IAM Policy - OIC Instance
************************************************************/
# 動的グループ(resource.type="integrationinstance") でやろうとしたができず
# 動的グループ(resource.id="CLIENT ID") でやろうとしたができず
# request.principal.id に CLIENT ID を指定する方法でできたためFIX
# CLIENT ID は、DefaultドメインのOracle Cloud サービスに作成されたOICから取得
# request.principal.compartment.id の制御は正直不要
resource "oci_identity_policy" "oic_instance_functions" {
  compartment_id = var.tenancy_ocid
  description    = "OIC Instance Policy for Functions"
  name           = "oic-instance-functions-policy"
  statements = [
    format(
      "allow any-user to read fn-app in compartment %s where all {request.principal.id= '%s', request.principal.compartment.id='%s'}",
      oci_identity_compartment.workload.name,
      oci_integration_integration_instance.developer.idcs_info[0].idcs_app_name,
      var.tenancy_ocid
    ),
    format(
      "allow any-user to read fn-function in compartment %s where all {request.principal.id= '%s', request.principal.compartment.id='%s'}",
      oci_identity_compartment.workload.name,
      oci_integration_integration_instance.developer.idcs_info[0].idcs_app_name,
      var.tenancy_ocid
    ),
    format(
      "allow any-user to use fn-invocation in compartment %s where all {request.principal.id= '%s', request.principal.compartment.id='%s'}",
      oci_identity_compartment.workload.name,
      oci_integration_integration_instance.developer.idcs_info[0].idcs_app_name,
      var.tenancy_ocid
    ),
  ]
}