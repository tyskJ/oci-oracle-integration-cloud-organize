/************************************************************
Reserved Public IPs
************************************************************/
resource "oci_core_public_ip" "flb" {
  compartment_id = oci_identity_compartment.workload.id
  lifetime       = "RESERVED"
  display_name   = "flb-public-ip"
  # # IP Pool を指定しない場合は、Oracle管理のPublic IPから予約される
  # public_ip_pool_id = null
  # # Ephemeral Public IP の場合は必須
  # private_ip_id     = null
  lifecycle {
    ignore_changes = [private_ip_id]
  }
}

/************************************************************
Load Balancer
************************************************************/
resource "oci_load_balancer_load_balancer" "flb" {
  compartment_id = oci_identity_compartment.workload.id
  display_name   = "flb"
  ip_mode        = "IPV4"
  is_private     = false
  reserved_ips {
    id = oci_core_public_ip.flb.id
  }
  subnet_ids = [
    oci_core_subnet.public_flb.id
  ]
  network_security_group_ids = [
    oci_core_network_security_group.sg_flb.id
  ]
  ipv6subnet_cidr = null
  shape           = "flexible"
  shape_details {
    maximum_bandwidth_in_mbps = 20
    minimum_bandwidth_in_mbps = 10
  }
  security_attributes          = {}
  is_delete_protection_enabled = false
  is_request_id_enabled        = false
  request_id_header            = null
}

/************************************************************
Backend Sets
************************************************************/
resource "oci_load_balancer_backend_set" "bks_http" {
  load_balancer_id = oci_load_balancer_load_balancer.flb.id
  name             = "http-backendset"
  policy           = "LEAST_CONNECTIONS"
  health_checker {
    protocol            = "HTTP"
    port                = 80
    is_force_plain_text = false
    interval_ms         = 10000
    timeout_in_millis   = 3000
    retries             = 3
    return_code         = 200
    url_path            = "/"
    response_body_regex = null
  }
  backend_max_connections = null
}

/************************************************************
Backends
************************************************************/
resource "oci_load_balancer_backend" "bk" {
  load_balancer_id = oci_load_balancer_load_balancer.flb.id
  backendset_name  = oci_load_balancer_backend_set.bks_http.name
  ip_address       = oci_core_instance.oracle_instance.private_ip
  port             = 80
  weight           = 1
  offline          = false
  backup           = false
  drain            = false
  max_connections  = null
}

/************************************************************
Listener - http
************************************************************/
resource "oci_load_balancer_listener" "listener_http" {
  load_balancer_id         = oci_load_balancer_load_balancer.flb.id
  name                     = "http-listener"
  protocol                 = "HTTP"
  port                     = 80
  hostname_names           = []
  default_backend_set_name = oci_load_balancer_backend_set.bks_http.name
  routing_policy_name      = null
  rule_set_names           = []
  #   # パスルートセットは廃止予定
  #   # ルーティングポリシーが上位互換のため、そちらを使うのが推奨
  #   path_route_set_name      = null
  connection_configuration {
    backend_tcp_proxy_protocol_options = []
    backend_tcp_proxy_protocol_version = 0
    idle_timeout_in_seconds            = "60"
  }
}