/************************************************************
Budgets
************************************************************/
resource "oci_budget_budget" "this" {
  compartment_id = var.tenancy_ocid
  display_name   = "budgets-1000JPY"
  description    = "specific compartments budgets threshold 1000 JPY"
  target_type    = "COMPARTMENT"
  targets = [
    oci_identity_compartment.workload.id
  ]
  reset_period                          = "MONTHLY"
  processing_period_type                = "MONTH"
  amount                                = 1000 # JPY
  budget_processing_period_start_offset = 1
}

/************************************************************
Alerts
************************************************************/
resource "oci_budget_alert_rule" "eighty_percent" {
  budget_id      = oci_budget_budget.this.id
  type           = "ACTUAL"
  threshold_type = "PERCENTAGE"
  threshold      = 80
  recipients     = var.email_address
  message        = "${oci_identity_compartment.workload.name} の利用料が800円を超えました"
}
