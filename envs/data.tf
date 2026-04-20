/************************************************************
Oracle Services Network
************************************************************/
data "oci_core_services" "this" {}

/************************************************************
Region
************************************************************/
data "oci_identity_regions" "regions" {}

/************************************************************
Availability Domain & Fault Domain
************************************************************/
data "oci_identity_availability_domain" "ads" {
  compartment_id = var.tenancy_ocid
  ad_number      = 1
}

data "oci_identity_fault_domains" "fds" {
  compartment_id      = var.tenancy_ocid
  availability_domain = data.oci_identity_availability_domain.ads.name
}

/************************************************************
OS Image
************************************************************/
# 商用環境では使用するイメージのOCIDはハードコードすること（時間の経過とともに変化するため）
data "oci_core_images" "oracle_supported_image" {
  compartment_id           = oci_identity_compartment.workload.id
  shape                    = "VM.Standard.E5.Flex"
  operating_system         = "Oracle Linux"
  operating_system_version = "10"
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
  state                    = "AVAILABLE"
}