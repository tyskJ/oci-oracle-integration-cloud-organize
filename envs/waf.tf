/************************************************************
Network Address Lists
************************************************************/
### CIDR
resource "oci_waf_network_address_list" "this" {
  compartment_id = oci_identity_compartment.workload.id
  display_name   = "white-list"
  type           = "ADDRESSES" # or VCN_ADDRESSES
  addresses = [
    var.source_ip
  ]
}

/************************************************************
Regional WAF Policy
************************************************************/
resource "oci_waf_web_app_firewall_policy" "waf_flb" {
  compartment_id = oci_identity_compartment.workload.id
  display_name   = "regional-waf-policy"
  #### Actions
  ### Default
  actions {
    code = 0
    name = "Pre-configured Check Action"
    type = "CHECK"
  }
  ### Default
  actions {
    code = 0
    name = "Pre-configured Allow Action"
    type = "ALLOW"
  }
  ### Default
  actions {
    code = 401
    name = "Pre-configured 401 Response Code Action"
    type = "RETURN_HTTP_RESPONSE"
    body {
      template = null
      text = jsonencode({
        code    = "401"
        message = "Unauthorized"
      })
      type = "STATIC_TEXT"
    }
    headers {
      name  = "Content-Type"
      value = "application/json"
    }
  }
  ### Custom
  actions {
    code = 403
    name = "Custom-configured-403-response-code-action"
    type = "RETURN_HTTP_RESPONSE"
    body {
      template = jsonencode({
        code      = "403"
        message   = "Forbidden"
        RequestId = "$${http.request.id}"
      })
      text = null
      type = "DYNAMIC"
    }
  }
  ### Custom
  actions {
    code = 429
    name = "Custom-configured-429-response-code-action"
    type = "RETURN_HTTP_RESPONSE"
    body {
      template = jsonencode({
        code      = "429"
        message   = "Too Many Requests"
        RequestId = "$${http.request.id}"
      })
      text = null
      type = "DYNAMIC"
    }
  }
  ### Custom
  actions {
    code = 503
    name = "Custom-configured-503-sorry-page"
    type = "RETURN_HTTP_RESPONSE"
    body {
      template = null
      text     = file("${path.module}/config/sorry_page.html")
      type     = "STATIC_TEXT"
    }
  }
  #### Access control
  ### Request access rules
  request_access_control {
    ### rulesの記載順序=評価順
    ### 上から評価さる
    ###　→　マッチしなければ次のルールを評価
    ###　→　マッチしたら評価終了
    ###　→　全てのルールにマッチしなければdefault_action
    rules {
      type               = "ACCESS_CONTROL"
      name               = "restrict-source-ip"
      condition_language = "JMESPATH"
      condition          = "!address_in_network_address_list(connection.source.address, ['${oci_waf_network_address_list.this.id}'])"
      action_name        = "Pre-configured 401 Response Code Action"
    }
    rules {
      type               = "ACCESS_CONTROL"
      name               = "restrict-country-jp"
      condition_language = "JMESPATH"
      condition          = "!i_contains(['JP'], connection.source.geo.countryCode)"
      action_name        = "Pre-configured 401 Response Code Action"
    }
    default_action_name = "Pre-configured Allow Action" # "Pre-configured Allow Action" or "Pre-configured 401 Response Code Action" or Custom
  }
  ### Response access rules
  # response_access_control {
  # }
  #### Rate limiting
  request_rate_limiting {
    ### rulesの記載順序=評価順
    ### 上から評価さる
    ### Conditionはオプション。指定しない場合は全リクエスト対象
    rules {
      type               = "REQUEST_RATE_LIMITING"
      name               = "rate-limit"
      condition_language = "JMESPATH"
      configurations {
        requests_limit             = 1
        period_in_seconds          = 1
        action_duration_in_seconds = 0
      }
      action_name = "Custom-configured-429-response-code-action"
    }
  }
  #### Protections
  # request_protection {
  # }
}

/************************************************************
Regional WAF - FLB Attached
************************************************************/
resource "oci_waf_web_app_firewall" "waf_flb" {
  compartment_id             = oci_identity_compartment.workload.id
  display_name               = "flb-waf"
  backend_type               = "LOAD_BALANCER"
  load_balancer_id           = oci_load_balancer_load_balancer.flb.id
  web_app_firewall_policy_id = oci_waf_web_app_firewall_policy.waf_flb.id
}