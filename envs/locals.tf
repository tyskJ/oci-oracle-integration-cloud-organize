/************************************************************
Region List
************************************************************/
locals {
  region_map = {
    for r in data.oci_identity_regions.regions.regions :
    r.key => r.name
  }
}

/************************************************************
Repository
************************************************************/
locals {
  repos = {
    com_stop = {
      prefix_name = "com_stop_mngt"
      fn_name     = "compute-stop"
    }
    waf_close = {
      prefix_name = "waf_close_mngt"
      fn_name     = "waf-close"
    }
  }
}

/************************************************************
Functions
************************************************************/
locals {
  apps = {
    com_stop = {
      name    = "compute-stop"
      fn_ocid = var.fn_stop_ocid
    }
    waf_close = {
      name    = "waf-close"
      fn_ocid = var.fn_close_ocid
    }
  }
}